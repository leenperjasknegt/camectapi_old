#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables
APP_USER="camectcontrol"
APP_DIR="/opt/camectcontrol"
SERVICE_NAME="camectcontrol"
PYTHON_VENV_DIR="$APP_DIR/venv"

echo "➡️ Starting interactive installation for the Camect Control app..."
echo "This script will: "
echo "- Install necessary dependencies (Python 3, python3-venv)."
echo "- Create a dedicated system user and application directory."
echo "- Set up a Python virtual environment."
echo "- Configure and enable a systemd service to run the app on startup."

echo ""
echo "🔐 Please enter the credentials required for the application."
echo "These values will be securely stored as environment variables for the service."

# Prompt for the Camect password
read -s -p "Enter your Camect password: " camect_password
echo ""
if [ -z "$camect_password" ]; then
    echo "❌ Error: Camect password cannot be empty. Aborting."
    exit 1
fi

# Prompt for the PIN and validate it
while true; do
    read -p "Enter your 4-digit PIN: " camect_pin
    if [[ "$camect_pin" =~ ^[0-9]{4}$ ]]; then
        break
    else
        echo "⚠️ Invalid PIN. Please enter exactly 4 digits."
    fi
done

echo "✅ Credentials received. Starting automated setup..."

# Step 1: Update package list and install necessary dependencies
echo "📦 Updating package list and installing core dependencies..."
sudo apt-get update -y
sudo apt-get install -y python3 python3-venv gunicorn

# Step 2: Create a dedicated user and directory for the application
echo "👤 Creating user and application directory..."
sudo useradd --system --no-create-home $APP_USER || true
sudo mkdir -p $APP_DIR
sudo chown -R $APP_USER:$APP_USER $APP_DIR

# Step 3: Create a Python virtual environment and install Flask and Gunicorn
echo "🐍 Creating Python virtual environment and installing dependencies..."
sudo -u $APP_USER python3 -m venv $PYTHON_VENV_DIR
sudo -u $APP_USER $PYTHON_VENV_DIR/bin/pip install Flask requests gunicorn

# Step 4: Copy application files
echo "📁 Copying application files..."
# Create the app files directly in the script for ease of use
sudo tee $APP_DIR/app.py > /dev/null << 'EOF'
import os
from functools import wraps
from flask import Flask, render_template, request, session, redirect, url_for, jsonify
import requests
from datetime import datetime, timedelta, timezone

# Set a secure secret key for session management.
app = Flask(__name__)
app.secret_key = os.urandom(24)
app.permanent_session_lifetime = timedelta(days=30)

# Retrieve sensitive information from environment variables
PIN = os.environ.get('CAMECT_PIN', '1234')
CAMECT_URL = os.environ.get('CAMECT_URL', 'https://8b79a7c9d.l.home.camect.com')
CAMECT_PASSWORD = os.environ.get('CAMECT_PASSWORD')

# CCTV System Configuration
camecturlfull = f'{CAMECT_URL}/api/SetOperationMode'
camect_home_info_url = f'{CAMECT_URL}/api/GetHomeInfo'
camectpassword = CAMECT_PASSWORD

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'logged_in' not in session:
            return redirect(url_for('dashboard'))
        return f(*args, **kwargs)
    return decorated_function

@app.route('/', methods=['GET', 'POST'])
def dashboard():
    """
    Main route that renders the single-page application.
    It handles login POST requests and serves the HTML.
    """
    if 'logged_in' in session:
        return render_template('index.html', logged_in=True)
    
    error = None
    if 'failed_attempts' not in session:
        session['failed_attempts'] = 0
    if 'locked_out_until' not in session:
        session['locked_out_until'] = None

    locked_out_until = session.get('locked_out_until')

    if locked_out_until and datetime.now(timezone.utc) < locked_out_until:
        remaining_time = locked_out_until - datetime.now(timezone.utc)
        minutes = int(remaining_time.total_seconds() / 60)
        seconds = int(remaining_time.total_seconds() % 60)
        error = f"Too many failed attempts. Please wait {minutes} minutes and {seconds} seconds."
        return render_template('index.html', logged_in=False, error=error)
            
    if request.method == 'POST':
        if request.form['pin'] == PIN:
            session['logged_in'] = True
            session.permanent = True
            session['failed_attempts'] = 0
            session['locked_out_until'] = None
            return redirect(url_for('dashboard'))
        else:
            session['failed_attempts'] += 1
            if session['failed_attempts'] >= 5:
                session['locked_out_until'] = datetime.now(timezone.utc) + timedelta(minutes=30)
                error = "Too many failed attempts. You are locked out for 30 minutes."
            else:
                remaining_attempts = 5 - session['failed_attempts']
                error = f"Invalid PIN. {remaining_attempts} attempts remaining."
        
        return render_template('index.html', logged_in=False, error=error)

    return render_template('index.html', logged_in=False, error=error)


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('dashboard'))


@app.route('/get_status', methods=['GET'])
@login_required
def get_status():
    if not camectpassword:
        return jsonify({'status': 'Configuration Error'}), 500
    try:
        r = requests.get(camect_home_info_url, verify=False, auth=('admin', camectpassword))
        r.raise_for_status()
        data = r.json()
        
        current_status = 'Unknown'
        if data.get('mode') == 'DEFAULT':
            current_status = 'Armed'
        elif data.get('mode') == 'HOME':
            current_status = 'Disarmed'
        
        return jsonify({'status': current_status})
    
    except requests.exceptions.RequestException as e:
        print(f"Error fetching status: {e}")
        return jsonify({'status': 'Error'}), 500


@app.route('/set_mode', methods=['POST'])
@login_required
def set_mode():
    requested_mode = request.form.get('mode')

    if not camectpassword:
        return jsonify({'success': False, 'error': 'Configuration Error'}), 500
    
    if requested_mode == 'arm':
        try:
            r = requests.post(f'{camecturlfull}', data={'Mode': 'DEFAULT'}, verify=False, auth=('admin', camectpassword))
            r.raise_for_status()
        except requests.exceptions.RequestException as e:
            print(f"Error arming system: {e}")
            return jsonify({'success': False, 'error': 'Error arming system'}), 500
        
        return jsonify({'success': True, 'status': 'Armed'})

    elif requested_mode == 'disarm':
        try:
            r = requests.post(f'{camecturlfull}', data={'Mode': 'HOME'}, verify=False, auth=('admin', camectpassword))
            r.raise_for_status()
        except requests.exceptions.RequestException as e:
            print(f"Error disarming system: {e}")
            return jsonify({'success': False, 'error': 'Error disarming system'}), 500
            
        return jsonify({'success': True, 'status': 'Disarmed'})

    return jsonify({'success': False, 'error': 'Invalid mode'}), 400


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
EOF

sudo mkdir -p $APP_DIR/templates
sudo tee $APP_DIR/templates/index.html > /dev/null << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <link rel="apple-touch-icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Cpath fill='%231f2937' d='M50 0 L10 20 V60 C10 80 50 100 50 100 C50 100 90 80 90 60 V20 Z'/%3E%3Cpath fill='%236B7280' d='M50 7 L86 26.6 V60 C86 75 50 90 50 90 C50 90 14 75 14 60 V26.6 Z'/%3E%3Cpath fill='%23e2e8f0' d='M50 40 A10 10 0 0 1 50 60 A10 10 0 0 1 50 40 Z'/%3E%3Cpath fill='%231a202c' d='M50 55 A5 5 0 0 0 50 45 A5 5 0 0 0 50 55 Z'/%3E%3C/svg%3E">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="CCTV">
    <title>CCTV Control</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap');
        body {
            font-family: 'Inter', sans-serif;
            background-color: #0d1117;
            color: #e2e8f0;
        }
        .keypad-btn {
            @apply w-24 h-24 sm:w-28 sm:h-28 text-white font-light transition-transform duration-200 transform hover:scale-105;
            background: rgba(45, 55, 72, 0.4);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.1);
            border-radius: 9999px;
            font-size: 2.5rem;
        }
        .keypad-btn:active {
            background: rgba(45, 55, 72, 0.6);
            transform: scale(1.02);
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1), inset 0 1px 0 rgba(255, 255, 255, 0.1);
        }
        #pin-display {
            letter-spacing: 0.5rem;
        }
        #clear-btn {
            font-size: 1.5rem;
        }
        @media (min-width: 640px) {
            .keypad-btn {
                font-size: 3.5rem;
            }
            #clear-btn {
                font-size: 2rem;
            }
        }
        .container {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            padding: 1rem;
        }
        .content-section {
            display: none;
        }
        .content-section.active {
            display: flex;
        }
    </style>
</head>
<body class="flex items-center justify-center min-h-screen">
    <div id="app-container" class="container">
        <div id="login-section" class="content-section flex-col items-center">
            <div class="bg-gray-900 bg-opacity-50 p-4 sm:p-8 rounded-3xl shadow-lg w-full max-w-sm flex flex-col items-center border border-gray-700">
                <div class="flex items-center justify-center w-24 h-24 mb-6">
                    <svg class="w-full h-full text-gray-400" xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>
                        <path fill='currentColor' d='M50 0 L10 20 V60 C10 80 50 100 50 100 C50 100 90 80 90 60 V20 Z'/>
                        <path fill='#1a202c' d='M50 7 L86 26.6 V60 C86 75 50 90 50 90 C50 90 14 75 14 60 V26.6 Z'/>
                        <path fill='#e2e8f0' d='M50 40 A10 10 0 0 1 50 60 A10 10 0 0 1 50 40 Z'/>
                        <path fill='#1a202c' d='M50 55 A5 5 0 0 0 50 45 A5 5 0 0 0 50 55 Z'/>
                    </svg>
                </div>
                <h1 class="text-3xl font-light text-center mb-6 text-gray-200">Enter PIN</h1>
                <form id="login-form" class="space-y-4 w-full">
                    <div class="flex justify-center mb-4">
                        <input type="password" id="pin-display" name="pin" readonly
                            class="w-full max-w-xs px-4 py-3 bg-gray-700 bg-opacity-30 rounded-lg text-center text-3xl sm:text-4xl font-mono tracking-widest text-white placeholder-gray-400 focus:outline-none"
                            maxlength="4" style="-webkit-text-security: disc;">
                    </div>
                    <div id="keypad" class="grid grid-cols-3 gap-6 w-full max-w-xs mx-auto">
                        <button type="button" class="keypad-btn">1</button>
                        <button type="button" class="keypad-btn">2</button>
                        <button type="button" class="keypad-btn">3</button>
                        <button type="button" class="keypad-btn">4</button>
                        <button type="button" class="keypad-btn">5</button>
                        <button type="button" class="keypad-btn">6</button>
                        <button type="button" class="keypad-btn">7</button>
                        <button type="button" class="keypad-btn">8</button>
                        <button type="button" class="keypad-btn">9</button>
                        <div></div>
                        <button type="button" class="keypad-btn">0</button>
                        <button type="button" id="clear-btn" class="keypad-btn text-xl sm:text-2xl"><i class="fas fa-backspace"></i></button>
                    </div>
                    <p id="error-message" class="text-center text-red-400 mt-4 hidden"></p>
                </form>
            </div>
        </div>

        <div id="dashboard-section" class="content-section flex-grow flex-col items-center justify-center space-y-8">
            <div id="status-display" class="flex flex-col items-center">
                </div>
            
            <div class="flex space-x-6">
                <button id="arm-button" class="w-32 h-32 rounded-full shadow-lg flex flex-col items-center justify-center transition-transform duration-300 transform hover:scale-105">
                    <i class="fas fa-lock text-4xl text-white"></i>
                    <span class="mt-2 text-sm font-semibold text-white">Arm</span>
                </button>

                <button id="disarm-button" class="w-32 h-32 rounded-full shadow-lg flex flex-col items-center justify-center transition-transform duration-300 transform hover:scale-105">
                    <i class="fas fa-lock-open text-4xl text-white"></i>
                    <span class="mt-2 text-sm font-semibold text-white">Disarm</span>
                </button>
            </div>
            
            <div class="w-full text-center mt-auto mb-4">
                <button id="logout-button" class="bg-gray-700 hover:bg-gray-600 text-gray-300 font-semibold py-2 px-4 rounded-lg transition-colors duration-300">
                    Logout
                </button>
            </div>
        </div>
    </div>

    <script>
        const loginSection = document.getElementById('login-section');
        const dashboardSection = document.getElementById('dashboard-section');
        const pinDisplay = document.getElementById('pin-display');
        const keypad = document.getElementById('keypad');
        const clearBtn = document.getElementById('clear-btn');
        const errorMessage = document.getElementById('error-message');
        const statusDisplay = document.getElementById('status-display');
        const armButton = document.getElementById('arm-button');
        const disarmButton = document.getElementById('disarm-button');
        const logoutButton = document.getElementById('logout-button');
        let statusInterval = null;

        // Function to show a specific section and hide others
        function showSection(sectionId) {
            const sections = document.querySelectorAll('.content-section');
            sections.forEach(section => {
                section.classList.remove('active');
            });
            document.getElementById(sectionId).classList.add('active');
        }

        // --- Login Logic ---
        keypad.addEventListener('click', (event) => {
            const btn = event.target.closest('.keypad-btn');
            if (!btn) return;

            if (btn.id === 'clear-btn') {
                pinDisplay.value = '';
                errorMessage.classList.add('hidden');
                errorMessage.textContent = '';
            } else if (!isNaN(parseInt(btn.textContent)) && pinDisplay.value.length < 4) {
                pinDisplay.value += btn.textContent.trim();
                if (pinDisplay.value.length === 4) {
                    handleLogin();
                }
            }
        });

        async function handleLogin() {
            const pin = pinDisplay.value;
            const formData = new FormData();
            formData.append('pin', pin);

            try {
                const response = await fetch("/", {
                    method: 'POST',
                    body: formData
                });
                
                if (response.redirected) {
                    window.location.href = response.url;
                } else {
                    const html = await response.text();
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(html, 'text/html');
                    const newErrorMessage = doc.getElementById('error-message').textContent;
                    if (newErrorMessage) {
                        errorMessage.textContent = newErrorMessage;
                        errorMessage.classList.remove('hidden');
                        pinDisplay.value = '';
                    }
                }
            } catch (error) {
                console.error("Login failed:", error);
                errorMessage.textContent = "Login failed. Please try again.";
                errorMessage.classList.remove('hidden');
            }
        }

        // --- Dashboard Logic ---
        function updateStatusDisplay(status) {
            statusDisplay.innerHTML = '';
            
            if (status === 'Armed') {
                statusDisplay.innerHTML = `<i class="fas fa-lock text-8xl text-red-500 animate-pulse"></i><p class="mt-2 text-xl font-semibold text-red-400">System is ARMED</p>`;
                armButton.disabled = true;
                armButton.classList.remove('bg-red-600', 'hover:bg-red-700');
                armButton.classList.add('bg-gray-600', 'cursor-not-allowed');
                disarmButton.disabled = false;
                disarmButton.classList.remove('bg-gray-600', 'cursor-not-allowed');
                disarmButton.classList.add('bg-green-600', 'hover:bg-green-700');
            } else if (status === 'Disarmed') {
                statusDisplay.innerHTML = `<i class="fas fa-lock-open text-8xl text-green-500"></i><p class="mt-2 text-xl font-semibold text-green-400">System is DISARMED</p>`;
                disarmButton.disabled = true;
                disarmButton.classList.remove('bg-green-600', 'hover:bg-green-700');
                disarmButton.classList.add('bg-gray-600', 'cursor-not-allowed');
                armButton.disabled = false;
                armButton.classList.remove('bg-gray-600', 'cursor-not-allowed');
                armButton.classList.add('bg-red-600', 'hover:bg-red-700');
            } else {
                statusDisplay.innerHTML = `<i class="fas fa-question-circle text-8xl text-gray-400"></i><p class="mt-2 text-xl font-semibold text-gray-400">Status Unknown</p>`;
                armButton.disabled = true;
                disarmButton.disabled = true;
            }
        }

        async function fetchStatus() {
            try {
                const response = await fetch("{{ url_for('get_status') }}");
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                const data = await response.json();
                updateStatusDisplay(data.status);
            } catch (error) {
                console.error("Failed to fetch status:", error);
                // Handle cases where login is required
                if (error.response && error.response.status === 401) {
                    showSection('login-section');
                    if (statusInterval) clearInterval(statusInterval);
                } else {
                    updateStatusDisplay("Error");
                }
            }
        }

        async function handleSetMode(mode) {
            const formData = new FormData();
            formData.append('mode', mode);

            try {
                const response = await fetch("{{ url_for('set_mode') }}", {
                    method: 'POST',
                    body: formData
                });
                const result = await response.json();
                if (result.success) {
                    updateStatusDisplay(result.status);
                } else {
                    alert(result.error);
                }
            } catch (error) {
                console.error("Failed to set mode:", error);
                alert("Failed to change mode.");
            }
        }

        armButton.addEventListener('click', () => handleSetMode('arm'));
        disarmButton.addEventListener('click', () => handleSetMode('disarm'));
        logoutButton.addEventListener('click', () => window.location.href = "{{ url_for('logout') }}");

        // --- Main App Initialization ---
        function initApp() {
            const loggedIn = {{ 'true' if logged_in else 'false' }};
            const loginError = "{{ error if error else '' }}";

            if (loggedIn) {
                showSection('dashboard-section');
                fetchStatus();
                if (!statusInterval) {
                    statusInterval = setInterval(fetchStatus, 5000);
                }
            } else {
                showSection('login-section');
                if (loginError) {
                    errorMessage.textContent = loginError;
                    errorMessage.classList.remove('hidden');
                }
                if (statusInterval) clearInterval(statusInterval);
            }
        }

        // Run on page load
        document.addEventListener('DOMContentLoaded', initApp);
    </script>
</body>
</html>
EOF

# Step 5: Configure the Gunicorn service file using the provided credentials
echo "⚙️ Creating systemd service file..."
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=Gunicorn instance for the Camect Control App
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment="CAMECT_PASSWORD=$camect_password"
Environment="CAMECT_PIN=$camect_pin"
ExecStart=$PYTHON_VENV_DIR/bin/gunicorn --workers 3 --bind 0.0.0.0:8000 app:app

[Install]
WantedBy=multi-user.target
EOF

# Step 6: Enable and start the service
echo "🚀 Enabling and starting the service..."
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME.service
sudo systemctl start $SERVICE_NAME.service

echo ""
echo "✅ Installation complete!"
echo "✨ Your application should now be accessible at http://<your_server_ip>:8000"
