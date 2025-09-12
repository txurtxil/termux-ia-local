# Versión: 2025-09-11 22:30:00
#!/bin/bash
# 🚀 Instalador IA Local Termux + Proot
# ✅ Optimizado para cualquier dispositivo (incluido Z Fold 4)
# ✅ Sin uso de /tmp — todo en subcarpetas de install.sh
# ✅ NUEVO: 5 Plantillas de IA Funcionales
# ✅ Genera y actualiza README.md automáticamente
# Autor: txurtxil
set -e

REPO_URL="https://github.com/txurtxil/termux-ia-local"
SCRIPT_PATH="$HOME/termux-ia-local"
TOKEN_DIR="$HOME/.tokens"
TOKEN_FILE="$TOKEN_DIR/github_token"
CHAT_SCRIPT="$SCRIPT_PATH/chatbot.py"
ENV_DIR="$SCRIPT_PATH/ia-env"
AGENT_DIR="$SCRIPT_PATH/agents"
AGENT_LOGS="$SCRIPT_PATH/agent_logs"
README_FILE="$SCRIPT_PATH/README.md"
LOCAL_INSTALLER="$HOME/install.sh"

mkdir -p "$TOKEN_DIR" "$SCRIPT_PATH" "$AGENT_DIR" "$AGENT_LOGS"
chmod 700 "$TOKEN_DIR"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =====================
# ✅ ¡CORREGIDO! Cambia el mirror de Termux MANUALMENTE (sin termux-change-repo)
setup_termux_mirror() {
    echo -e "${BLUE}[*] Configurando mirror de Termux (manual)...${NC}"
    
    # Crear directorios necesarios
    mkdir -p "$PREFIX/etc/apt/sources.list.d" 2>/dev/null || true
    
    # Forzar el uso del mirror de Cloudflare (el más confiable)
    echo "deb https://packages-cf.termux.dev/apt/termux-main stable main" > "$PREFIX/etc/apt/sources.list"
    echo "deb https://packages-cf.termux.dev/apt/termux-games games stable" > "$PREFIX/etc/apt/sources.list.d/games.list"
    echo "deb https://packages-cf.termux.dev/apt/termux-science science stable" > "$PREFIX/etc/apt/sources.list.d/science.list"
    
    # Forzar actualización de paquetes
    pkg update -y 2>/dev/null || {
        echo -e "${YELLOW}[!] Advertencia: pkg update falló, pero continuaremos.${NC}"
    }
    
    echo -e "${GREEN}[+] Mirror configurado y paquetes actualizados.${NC}"
}
# =====================

# Modelos
declare -A MODELS=(
    ["1"]="TinyLlama-1.1B-Chat (Velocidad)"
    ["2"]="Mistral-7B Q4 (Calidad)"
    ["3"]="Mistral-7B Q3 (Rápido + Calidad)" # <- El elegido para agentes
    ["4"]="Phi-2 (Experimental)"
)

MODEL_URLS=(
    ["1"]="https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
    ["2"]="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
    ["3"]="https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q3_K_M.gguf"
    ["4"]="https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf"
)

MODEL_FILES=(
    ["1"]="tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf"
    ["2"]="mistral-7b-instruct-v0.2.Q4_K_M.gguf"
    ["3"]="mistral-7b-instruct-v0.2.Q3_K_M.gguf"
    ["4"]="phi-2.Q4_K_M.gguf"
)

# =====================
# FUNCIONES PARA AGENTES
# =====================

# Función para limpiar líneas problemáticas antiguas del .bashrc
clean_old_bashrc_entries() {
    echo -e "${BLUE}[*] Limpiando entradas antiguas de ~/.bashrc...${NC}"
    # Crear .bashrc si no existe
    [ ! -f ~/.bashrc ] && touch ~/.bashrc
    cp ~/.bashrc ~/.bashrc.backup.$(date +%s) 2>/dev/null || true
    grep -v "# 📈 Para el Agente Analista de Uso" ~/.bashrc | \
    grep -v "# 🧠 Iniciar Agente Terminal Pro" | \
    grep -v "# 🤖 Iniciar Agente Auto-Scripter" | \
    grep -v "ia-env/bin/activate" | \
    grep -v "run_terminal_pro.sh" | \
    grep -v "run_auto_scripter.sh" | \
    grep -v "log_command" | \
    grep -v "# 🧹 Auto-Organizador de Archivos" | \
    grep -v "# 📊 Analista de Red y Ancho de Banda" | \
    grep -v "# 🛡️ Guardián de Seguridad" > ~/.bashrc.tmp && mv ~/.bashrc.tmp ~/.bashrc
    echo -e "${GREEN}[+] Limpieza de ~/.bashrc completada.${NC}"
}

# Función para instalar cron dentro de Ubuntu si no está presente
ensure_cron_installed() {
    echo -e "${BLUE}[*] Verificando/Instalando 'cron' en Ubuntu...${NC}"
    proot-distro login ubuntu -- bash -c "
        if ! command -v crontab > /dev/null 2>&1; then
            apt update -y && apt install -y cron
            echo -e \"${GREEN}[+] 'cron' instalado.${NC}\"
        else
            echo -e \"${GREEN}[+] 'cron' ya está instalado.${NC}\"
        fi
    "
}

# Función para instalar dependencias de Termux
install_termux_dependencies() {
    echo -e "${BLUE}[*] Instalando dependencias de Termux...${NC}"
    pkg install termux-api -y
    if pkg list-all | grep -q "termux-wake-lock"; then
        pkg install termux-wake-lock -y
        echo -e "${GREEN}[+] termux-wake-lock instalado.${NC}"
    else
        echo -e "${YELLOW}[!] termux-wake-lock no disponible. Se omitirá.${NC}"
    fi
    echo -e "${GREEN}[+] Dependencias de Termux listas.${NC}"
}

# Función para instalar dependencias dentro de Ubuntu Proot
install_ubuntu_agent_dependencies() {
    echo -e "${BLUE}[*] Instalando dependencias de Ubuntu para agentes...${NC}"
    proot-distro login ubuntu -- bash -c "
        apt update -y
        apt install -y inotify-tools
        echo -e \"${GREEN}[+] Dependencias de Ubuntu listas.${NC}\"
    "
}

# CORRECCIÓN PRINCIPAL: Creamos la estructura de carpetas en Ubuntu ANTES de descargar modelos
ensure_ubuntu_directory_structure() {
    proot-distro login ubuntu -- bash -c "
        mkdir -p \"$SCRIPT_PATH/models\" \"$SCRIPT_PATH/agents\" \"$SCRIPT_PATH/agent_logs\"
    "
}

# =====================
# 🧠 PLANTILLA 1: TERMINAL PRO (ASISTENTE PROACTIVO)
# =====================
generate_terminal_pro_agent() {
    local model_file=${MODEL_FILES[3]} # Mistral Q3
    proot-distro login ubuntu -- bash -c "
        mkdir -p \"$AGENT_DIR\"
        cat > \"$AGENT_DIR/terminal_pro.py\" << 'EOF'
import os
import subprocess
import time
from datetime import datetime
from llama_cpp import Llama

llm = Llama(
    model_path='./models/$model_file',
    n_ctx=2048,
    n_threads=4,
    n_batch=512,
    verbose=False,
    chat_format='mistral-instruct'
)

def send_notification(title, content):
    subprocess.run(['termux-notification', '-t', title, '-c', content])

def get_battery_level():
    result = subprocess.run(['termux-battery-status'], capture_output=True, text=True)
    import json
    try:
        data = json.loads(result.stdout)
        return data.get('percentage', 100)
    except:
        return 100

def analyze_history():
    bash_history = []
    chat_history = []

    if os.path.exists('/data/data/com.termux/files/home/.bash_history'):
        with open('/data/data/com.termux/files/home/.bash_history', 'r') as f:
            lines = f.readlines()[-20:]
            bash_history = [line.strip() for line in lines if line.strip()]

    if os.path.exists('./chat_history.txt'):
        with open('./chat_history.txt', 'r') as f:
            lines = f.readlines()[-20:]
            chat_history = [line.strip() for line in lines if line.strip()]

    prompt = f\"\"\"
    Eres un asistente de terminal proactivo. Analiza el historial.
    Historial de Comandos (últimos 20):
    {bash_history}
    Historial de Chat IA (últimas 20 líneas):
    {chat_history}
    Genera UNA sugerencia útil. Empieza con \"💡 Sugerencia: \"
    \"\"\"

    output = llm.create_chat_completion(
        messages=[{'role': 'user', 'content': prompt}],
        max_tokens=150,
        temperature=0.2,
        top_p=0.9,
        repeat_penalty=1.1
    )

    suggestion = output['choices'][0]['message']['content'].strip()
    if '💡 Sugerencia:' not in suggestion:
        suggestion = '💡 Sugerencia: ' + suggestion
    send_notification('🧠 Terminal Pro', suggestion)

def main():
    battery = get_battery_level()
    if battery < 20:
        return
    analyze_history()

if __name__ == '__main__':
    main()
EOF

        chmod +x \"$AGENT_DIR/terminal_pro.py\"

        cat > \"$AGENT_DIR/run_terminal_pro.sh\" << 'BASH_EOF'
#!/bin/bash
cd \"$SCRIPT_PATH\"
if [ -f \"ia-env/bin/activate\" ] && [ -f \"agents/terminal_pro.py\" ]; then
    source ia-env/bin/activate
    python3 agents/terminal_pro.py
fi
BASH_EOF

        chmod +x \"$AGENT_DIR/run_terminal_pro.sh\"
    "

    clean_old_bashrc_entries
    if ! grep -q "run_terminal_pro.sh" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# 🧠 Iniciar Agente Terminal Pro en segundo plano" >> ~/.bashrc
        echo "if [ -f \"$AGENT_DIR/run_terminal_pro.sh\" ]; then" >> ~/.bashrc
        echo "    nohup bash \"$AGENT_DIR/run_terminal_pro.sh\" > /dev/null 2>&1 &" >> ~/.bashrc
        echo "    echo -e '\\033[1;36m[🧠 Terminal Pro: Agente activo]\\033[0m'" >> ~/.bashrc
        echo "fi" >> ~/.bashrc
        echo -e "${GREEN}[+] Agente 'Terminal Pro' configurado en .bashrc.${NC}"
    fi
}

# =====================
# 🧹 PLANTILLA 2: AUTO-ORGANIZADOR DE ARCHIVOS
# =====================
generate_auto_organizer_agent() {
    proot-distro login ubuntu -- bash -c "
        mkdir -p \"$AGENT_DIR\"
        cat > \"$AGENT_DIR/auto_organizer.py\" << 'EOF'
import os
import shutil
from pathlib import Path
import subprocess

def send_notification(title, content):
    subprocess.run(['termux-notification', '-t', title, '-c', content])

def organize_downloads():
    download_path = Path('/sdcard/Download')
    if not download_path.exists():
        return

    categories = {
        'Images': ['.jpg', '.jpeg', '.png', '.gif', '.webp'],
        'Documents': ['.pdf', '.doc', '.docx', '.txt', '.xls', '.xlsx'],
        'Videos': ['.mp4', '.mkv', '.avi', '.mov'],
        'Audio': ['.mp3', '.wav', '.flac'],
        'Archives': ['.zip', '.rar', '.7z', '.tar', '.gz']
    }

    organized_count = 0
    for file in download_path.iterdir():
        if file.is_file():
            for category, extensions in categories.items():
                if file.suffix.lower() in extensions:
                    target_dir = download_path / category
                    target_dir.mkdir(exist_ok=True)
                    shutil.move(str(file), str(target_dir / file.name))
                    organized_count += 1
                    break

    if organized_count > 0:
        send_notification('🧹 Auto-Organizador', f'✅ {organized_count} archivos organizados.')

if __name__ == '__main__':
    organize_downloads()
EOF

        chmod +x \"$AGENT_DIR/auto_organizer.py\"
    "

    ensure_cron_installed
    proot-distro login ubuntu -- bash -c "
        (crontab -l 2>/dev/null; echo \"0 */2 * * * cd $SCRIPT_PATH && [ -f ia-env/bin/activate ] && source ia-env/bin/activate && [ -f agents/auto_organizer.py ] && python3 agents/auto_organizer.py\") | crontab -
    "
    echo -e "${GREEN}[+] Agente 'Auto-Organizador' programado en cron (cada 2 horas).${NC}"
}

# =====================
# 📊 PLANTILLA 3: ANALISTA DE RED Y ANCHO DE BANDA
# =====================
generate_bandwidth_monitor_agent() {
    # Instalar dependencias de Termux
    pkg install termux-telephony -y 2>/dev/null || echo -e "${YELLOW}[!] termux-telephony no disponible.${NC}"

    proot-distro login ubuntu -- bash -c "
        mkdir -p \"$AGENT_DIR\"
        cat > \"$AGENT_DIR/bandwidth_monitor.py\" << 'EOF'
import subprocess
import json
import os

def send_notification(title, content):
    subprocess.run(['termux-notification', '-t', title, '-c', content])

def get_data_usage():
    # Placeholder: En un entorno real, aquí iría la lógica para obtener el uso de datos.
    # Por ahora, simulamos un valor.
    return 5.2  # GB usados

def check_bandwidth():
    used_gb = get_data_usage()
    monthly_limit = 10.0  # GB (configurable)
    if used_gb > monthly_limit * 0.8:
        send_notification('⚠️ Alerta de Datos', f'Has usado {used_gb}GB de {monthly_limit}GB. ¡Cuidado!')

if __name__ == '__main__':
    check_bandwidth()
EOF

        chmod +x \"$AGENT_DIR/bandwidth_monitor.py\"
    "

    ensure_cron_installed
    proot-distro login ubuntu -- bash -c "
        (crontab -l 2>/dev/null; echo \"0 */6 * * * cd $SCRIPT_PATH && [ -f ia-env/bin/activate ] && source ia-env/bin/activate && [ -f agents/bandwidth_monitor.py ] && python3 agents/bandwidth_monitor.py\") | crontab -
    "
    echo -e "${GREEN}[+] Agente 'Analista de Red' programado en cron (cada 6 horas).${NC}"
}

# =====================
# 🛡️ PLANTILLA 4: GUARDIÁN DE SEGURIDAD (ESCÁNER DE PERMISOS)
# =====================
generate_security_guardian_agent() {
    proot-distro login ubuntu -- bash -c "
        mkdir -p \"$AGENT_DIR\"
        cat > \"$AGENT_DIR/security_guardian.py\" << 'EOF'
import subprocess
import json

SENSITIVE_PERMISSIONS = [
    'android.permission.READ_SMS',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.RECORD_AUDIO',
    'android.permission.CAMERA'
]

def send_notification(title, content):
    subprocess.run(['termux-notification', '-t', title, '-c', content])

def get_installed_packages():
    result = subprocess.run(['pm', 'list', 'packages', '-3'], capture_output=True, text=True)
    packages = [line.split(':')[1].strip() for line in result.stdout.splitlines() if ':' in line]
    return packages

def get_package_permissions(package_name):
    result = subprocess.run(['dumpsys', 'package', package_name], capture_output=True, text=True)
    permissions = []
    for line in result.stdout.splitlines():
        if 'android.permission.' in line and 'granted=true' in line:
            perm = line.split(' ')[0].strip()
            permissions.append(perm)
    return permissions

def scan_permissions():
    risky_apps = []
    packages = get_installed_packages()
    for pkg in packages:
        perms = get_package_permissions(pkg)
        risky_perms = [p for p in perms if p in SENSITIVE_PERMISSIONS]
        if risky_perms:
            risky_apps.append((pkg, risky_perms))
    
    if risky_apps:
        report = 'Apps con permisos sensibles:
'
        for app, perms in risky_apps[:5]:  # Limitar a 5 apps para no saturar la notificación
            report += f'- {app}: {', '.join(perms)}
'
        send_notification('🛡️ Informe de Seguridad', report)

if __name__ == '__main__':
    scan_permissions()
EOF

        chmod +x \"$AGENT_DIR/security_guardian.py\"
    "

    ensure_cron_installed
    proot-distro login ubuntu -- bash -c "
        (crontab -l 2>/dev/null; echo \"0 9 * * 1 cd $SCRIPT_PATH && [ -f ia-env/bin/activate ] && source ia-env/bin/activate && [ -f agents/security_guardian.py ] && python3 agents/security_guardian.py\") | crontab -
    "
    echo -e "${GREEN}[+] Agente 'Guardián de Seguridad' programado en cron (lunes a las 9 AM).${NC}"
}

# =====================
# 🤖 PLANTILLA 5: GENERADOR DE SCRIPTS AUTOMÁTICOS (AVANZADO)
# =====================
generate_advanced_scripter_agent() {
    local model_file=${MODEL_FILES[3]} # Mistral Q3
    proot-distro login ubuntu -- bash -c "
        mkdir -p \"$AGENT_DIR\"
        cat > \"$AGENT_DIR/advanced_scripter.py\" << 'EOF'
import os
import subprocess
from llama_cpp import Llama

llm = Llama(
    model_path='./models/$model_file',
    n_ctx=2048,
    n_threads=4,
    n_batch=512,
    verbose=False,
    chat_format='mistral-instruct'
)

def send_notification(title, content):
    subprocess.run(['termux-notification', '-t', title, '-c', content])

def generate_script(prompt):
    full_prompt = f\"\"\"
    Eres un experto en Bash y Termux. Genera un script de Bash para Termux que cumpla con el siguiente requerimiento.
    El script debe ser seguro, eficiente y usar comandos disponibles en Termux.
    Solo devuelve el código del script, sin explicaciones ni texto adicional.

    Requerimiento: {prompt}
    \"\"\"

    output = llm.create_chat_completion(
        messages=[{'role': 'user', 'content': full_prompt}],
        max_tokens=500,
        temperature=0.1
    )
    return output['choices'][0]['message']['content'].strip()

def save_script(script_name, script_content):
    bin_dir = '/data/data/com.termux/files/home/bin'
    os.makedirs(bin_dir, exist_ok=True)
    script_path = f'{bin_dir}/{script_name}.sh'
    with open(script_path, 'w') as f:
        f.write('#!/bin/bash\\n')
        f.write(script_content + '\\n')
    subprocess.run(['chmod', '+x', script_path])
    send_notification('🤖 Auto-Scripter Avanzado', f'✅ Script \\'{script_name}.sh\\' creado en ~/bin/')
    return script_path

def main():
    # Pedir al usuario la descripción de la tarea
    print('Describe la tarea que quieres automatizar y presiona Enter:')
    prompt = input('> ').strip()
    if not prompt:
        print('No se proporcionó ninguna tarea. Saliendo.')
        return

    # Generar el script
    print('Generando script con IA...')
    script_content = generate_script(prompt)
    if not script_content:
        print('No se pudo generar el script. Inténtalo de nuevo.')
        return

    # Pedir el nombre del script
    script_name = input('Nombre para el script (sin .sh): ').strip()
    if not script_name:
        script_name = 'mi_script'

    # Guardar el script
    script_path = save_script(script_name, script_content)
    print(f'✅ Script guardado en: {script_path}')
    print('Puedes ejecutarlo con: ' + script_name + '.sh')

if __name__ == '__main__':
    main()
EOF

        chmod +x \"$AGENT_DIR/advanced_scripter.py\"
    "

    # ✅ CORREGIDO: Crear alias que ejecute el script DENTRO de Ubuntu Proot
    if ! grep -q "ia-advanced-scripter" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# 🤖 Alias para el Generador de Scripts Avanzado" >> ~/.bashrc
        echo "alias ia-advanced-scripter='proot-distro login ubuntu -- bash -c \"cd \\\"$SCRIPT_PATH\\\" && [ -f ia-env/bin/activate ] && source ia-env/bin/activate && python3 agents/advanced_scripter.py\"'" >> ~/.bashrc
        echo -e "${GREEN}[+] Alias 'ia-advanced-scripter' creado.${NC}"
    else
        echo -e "${YELLOW}[!] El alias 'ia-advanced-scripter' ya existe.${NC}"
    fi
}

# Función para mostrar el submenú de plantillas
show_agent_templates_menu() {
    while true; do
        clear
        echo -e "${GREEN}=================================${NC}"
        echo -e "${GREEN}   🤖 Plantillas de IA (Agentes)  ${NC}"
        echo -e "${GREEN}=================================${NC}"
        echo -e "1) 🧠 Terminal Pro (Asistente Proactivo)"
        echo -e "2) 🧹 Auto-Organizador de Archivos"
        echo -e "3) 📊 Analista de Red y Ancho de Banda"
        echo -e "4) 🛡️ Guardián de Seguridad (Escáner de Permisos)"
        echo -e "5) 🤖 Generador de Scripts Automáticos (Avanzado)"
        echo -e "6) Volver al menú principal"
        echo -e "${GREEN}=================================${NC}"
        read -p "Selecciona una plantilla: " agent_opt

        case $agent_opt in
            1|2|3|4|5)
                echo -e "${BLUE}[*] Instalando dependencias...${NC}"
                install_termux_dependencies
                install_ubuntu_agent_dependencies
                echo -e "${BLUE}[*] Preparando estructura de directorios en Ubuntu...${NC}"
                ensure_ubuntu_directory_structure
                echo -e "${BLUE}[*] Descargando modelo Mistral-7B Q3 (si no está)...${NC}"
                download_model "3"
                case $agent_opt in
                    1) echo -e "${BLUE}[*] Generando Agente 'Terminal Pro'...${NC}"; generate_terminal_pro_agent ;;
                    2) echo -e "${BLUE}[*] Generando Agente 'Auto-Organizador'...${NC}"; generate_auto_organizer_agent ;;
                    3) echo -e "${BLUE}[*] Generando Agente 'Analista de Red'...${NC}"; generate_bandwidth_monitor_agent ;;
                    4) echo -e "${BLUE}[*] Generando Agente 'Guardián de Seguridad'...${NC}"; generate_security_guardian_agent ;;
                    5) echo -e "${BLUE}[*] Generando Agente 'Generador de Scripts'...${NC}"; generate_advanced_scripter_agent ;;
                esac
                echo -e "${GREEN}[+] ¡Listo! Reinicia Termux si es necesario.${NC}"
                ;;
            6) break ;;
            *) echo -e "${RED}Opción inválida.${NC}" ;;
        esac
        read -p "Presiona Enter para continuar..." dummy
    done
}

# Funciones originales
setup_termux_proot() {
    echo -e "${BLUE}[*] Instalando Ubuntu...${NC}"
    pkg update -y && pkg install proot-distro git wget -y
    proot-distro install ubuntu
    echo -e "${GREEN}[+] Listo.${NC}"
}

enter_ubuntu() {
    echo -e "${BLUE}[*] Configurando Python...${NC}"
    proot-distro login ubuntu -- bash -c "
        mkdir -p \"$SCRIPT_PATH/models\" \"$SCRIPT_PATH/agents\" \"$SCRIPT_PATH/agent_logs\"
        cd \"$SCRIPT_PATH\"
        apt update -y
        apt install -y python3 python3-pip python3-venv wget git
        [ -d ia-env ] || python3 -m venv ia-env
        source ia-env/bin/activate
        pip install --upgrade pip
        pip install llama-cpp-python
        touch .installed
        echo -e \"${GREEN}[+] Python listo.${NC}\"
    "
}

download_model() {
    local model_choice=$1
    local model_url=${MODEL_URLS[$model_choice]}
    local model_file=${MODEL_FILES[$model_choice]}
    echo -e "${BLUE}[*] Descargando ${MODELS[$model_choice]}...${NC}"
    proot-distro login ubuntu -- bash -c "
        cd \"$SCRIPT_PATH/models\"
        if [ ! -f \"$model_file\" ]; then
            wget -c \"$model_url\"
            echo -e \"${GREEN}[+] Descargado: $model_file${NC}\"
        else
            echo -e \"${YELLOW}[!] El modelo ya existe.${NC}\"
        fi
    "
}

generate_chat_script() {
    local model_choice=$1
    local model_file=${MODEL_FILES[$model_choice]}
    local chat_format="chatml"
    local system_prompt="Eres un asistente útil y claro."
    [[ "$model_choice" == "2" || "$model_choice" == "3" ]] && chat_format="mistral-instruct" && system_prompt=""
    proot-distro login ubuntu -- bash -c "
        cat > \"$CHAT_SCRIPT\" << 'EOF'
from llama_cpp import Llama
import sys
print('\\033[1;36m💬 Chat IA Local - Escribe \"salir\"\\033[0m')
llm = Llama(
    model_path='./models/$model_file',
    n_ctx=3000,
    n_threads=8,
    n_batch=512,
    verbose=False,
    chat_format='$chat_format'
)
while True:
    user_input = input('\\n\\033[1;33mTú: \\033[0m').strip()
    if user_input.lower() in ['salir', 'exit', 'quit']:
        print('\\033[1;31m👋 Adiós\\033[0m')
        break
    messages = []
    if '$system_prompt' != '':
        messages.append({'role': 'system', 'content': '$system_prompt'})
    messages.append({'role': 'user', 'content': user_input})
    output = llm.create_chat_completion(
        messages=messages,
        max_tokens=250,
        temperature=0.3,
        top_p=0.95,
        repeat_penalty=1.1
    )
    response = output['choices'][0]['message']['content'].strip()
    print(f'\\033[1;32m🤖 IA: \\033[0m{response}')
EOF
        echo -e \"${GREEN}[+] Chatbot generado.${NC}\"
    "
}

create_alias() {
    clean_old_bashrc_entries
    proot-distro login ubuntu -- bash -c "
        echo \"alias ia-chat='cd \\\"$SCRIPT_PATH\\\" && [ -f ia-env/bin/activate ] && source ia-env/bin/activate && [ -f chatbot.py ] && python3 chatbot.py'\" >> ~/.bashrc
        echo -e \"${GREEN}[+] Usa: ia-chat${NC}\"
    "
}

# ✅ CORRECCIÓN DE TOKEN DE GITHUB
backup_to_github() {
    if [ ! -f "$TOKEN_FILE" ]; then
        echo -e "${RED}[!] Ingresa token primero (opción 5).${NC}"
        return 1
    fi

    generate_readme

    # ✅ Leer el token ANTES de entrar en el entorno Ubuntu
    GITHUB_TOKEN=$(cat "$TOKEN_FILE")

    proot-distro login ubuntu -- bash -c "
        cd \"$SCRIPT_PATH\"
        cp \"$HOME/install.sh\" .
        git init
        git config --global user.email 'user@local'
        git config --global user.name 'TermuxBot'
        git add install.sh README.md
        git commit -m 'Backup automático $(date '+%Y-%m-%d %H:%M:%S')'
        git branch -M main
        # ✅ CORREGIDO: Inyectar el token directamente en la URL
        git remote remove origin 2>/dev/null || true
        git remote add origin https://$GITHUB_TOKEN@github.com/txurtxil/termux-ia-local.git
        if git push -u origin main --force; then
            echo -e \"${GREEN}✅ install.sh + README.md subidos.${NC}\"
        else
            echo -e \"${RED}❌ Error. Verifica token y repo.${NC}\"
        fi
    "
}

# Función para generar el README.md
generate_readme() {
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    cat > "$README_FILE" << EOF
# 🤖 IA Local en Termux para Android (Z Fold 4 y superiores)

> **Ejecuta modelos de lenguaje como Mistral, TinyLlama o Phi-2 directamente en tu móvil — sin internet, sin root, sin servidor.**

✅ Compatible con **Samsung Galaxy Z Fold 4, 5, S23/S24 Ultra, y cualquier Android con 8GB+ RAM.**

---

## 🚀 Instalación (1 solo comando)

Abre **Termux** (instálalo desde [F-Droid](https://f-droid.org/en/packages/com.termux/ )) y ejecuta:

\`\`\`bash
curl -sL https://raw.githubusercontent.com/txurtxil/termux-ia-local/main/install.sh  | bash
\`\`\`

> ⚠️ No uses la versión de Termux de la Play Store — puede fallar. Usa siempre la de F-Droid.

---

## 🎮 Menú interactivo

Tras instalar, se abre un menú simple y responsive:

\`\`\`
==========================
   🤖 IA Local Termux
==========================
1) Instalar Ubuntu + Python
2) Descargar modelo IA
3) Iniciar chat (ia-chat)
4) Subir install.sh + README.md a GitHub
5) Ingresar Token GitHub
6) Limpiar token
7) Salir
8) Configurar Agentes de IA (Plantillas)  <-- ¡NUEVO!
==========================
Modelos:
1) TinyLlama-1.1B-Chat (Velocidad)
2) Mistral-7B Q4 (Calidad)
3) Mistral-7B Q3 (Rápido + Calidad)
4) Phi-2 (Experimental)
==========================
\`\`\`

---

## 🤖 Plantillas de IA (Agentes en Segundo Plano)

¡Transforma tu terminal en un asistente proactivo! Elige una plantilla y tu IA trabajará para ti en segundo plano.

**Cómo usarlo:**
1.  En el menú principal, selecciona la opción \`8) Configurar Agentes de IA (Plantillas)\`.
2.  Elige la plantilla que desees.
3.  ¡Listo! El agente se instalará y comenzará a funcionar automáticamente.

**Plantillas Disponibles:**
*   **🧠 Terminal Pro:** Tu asistente personal. Analiza tu historial y te da sugerencias inteligentes al abrir la terminal.
*   **🧹 Auto-Organizador de Archivos:** Escanea tu carpeta de descargas y organiza automáticamente tus archivos por tipo (imágenes, documentos, etc.).
*   **📊 Analista de Red y Ancho de Banda:** Monitorea tu consumo de datos móviles y te alerta si estás cerca de superar tu límite.
*   **🛡️ Guardián de Seguridad:** Escanea las aplicaciones instaladas y te alerta si alguna tiene permisos potencialmente peligrosos.
*   **🤖 Generador de Scripts Automáticos:** Crea scripts Bash personalizados basados en tus necesidades. Ejecútalo manualmente con \`ia-advanced-scripter\`.

> 💡 Todos los agentes usan el modelo Mistral-7B Q3 para un equilibrio perfecto entre inteligencia y rendimiento. Solo se ejecutan cuando la batería está por encima del 20%.

---

## ▶️ Cómo usar el chatbot

1. Elige opción \`2\` y descarga un modelo (recomendado: \`3\` Mistral Q3 para equilibrio).
2. Elige opción \`3\` para iniciar el chat.
3. ¡Pregunta lo que quieras!

> 💡 Usa \`ia-chat\` en cualquier momento para volver al chat.

---

## 🔄 Backup a GitHub

1. Opción \`5\`: Ingresa tu token de GitHub.
2. Opción \`4\`: Sube automáticamente \`install.sh\` y \`README.md\` con versión y fecha.

> 🔐 Tu token nunca se commitea — se usa solo para autenticar el push.

---

## 🛠️ Requisitos

- Android 9+ (ARM64)
- Termux (desde F-Droid)
- 8GB+ RAM (para Mistral 7B)
- 6GB+ espacio libre
- Conexión a internet (solo para descargar modelo la primera vez)

---

## 💡 Ideas de uso

- Automatizar respuestas con Tasker.
- Crear asistente de voz offline.
- Integrar con Auto.js o Automate.
- Usar como backend local para apps propias.

---

## 📜 Licencia

MIT — Haz lo que quieras con este código 😊

---

> **Hecho con ❤️ para devs móviles — Versión generada: $TIMESTAMP**
EOF
    echo -e "${GREEN}[+] README.md generado.${NC}"
}

request_github_token() {
    echo -e "${YELLOW}[*] Token GitHub:${NC}"
    read -s GITHUB_TOKEN
    echo "$GITHUB_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}[+] Guardado.${NC}"
}

show_menu() {
    clear
    echo -e "${GREEN}==========================${NC}"
    echo -e "${GREEN}    🤖 IA Local Termux     ${NC}"
    echo -e "${GREEN}==========================${NC}"
    echo -e "1) Instalar Ubuntu + Python"
    echo -e "2) Descargar modelo IA"
    echo -e "3) Iniciar chat (ia-chat)"
    echo -e "4) Subir install.sh + README.md a GitHub"
    echo -e "5) Ingresar Token GitHub"
    echo -e "6) Limpiar token"
    echo -e "7) Salir"
    echo -e "8) Configurar Agentes de IA (Plantillas)"
    echo -e "${GREEN}==========================${NC}"
    echo -e "${YELLOW}Modelos:${NC}"
    for i in {1..4}; do
        echo -e "$i) ${MODELS[$i]}"
    done
    echo -e "${GREEN}==========================${NC}"
}

main() {
    # ✅ ¡NUEVA LÓGICA! Si se ejecuta desde un pipe, descargar una copia local
    if [ ! -t 0 ] && [ ! -f "$LOCAL_INSTALLER" ]; then
        echo -e "${BLUE}[*] Descargando copia local del instalador...${NC}"
        curl -sL "$REPO_URL/raw/main/install.sh" -o "$LOCAL_INSTALLER"
        chmod +x "$LOCAL_INSTALLER"
        echo -e "${GREEN}[+] Copia local guardada en ~/install.sh${NC}"
        # ✅ Re-ejecutar desde el archivo local
        exec bash "$LOCAL_INSTALLER"
    fi

    # ✅ Limpiar rastros antiguos y generar README inicial
    clean_old_bashrc_entries
    generate_readme

    # ✅ ¡CORREGIDO! Configurar mirror de Termux MANUALMENTE
    setup_termux_mirror

    # ✅ ¡NUEVA LÓGICA! Si es la primera vez (no existe ia-env), inicia la instalación automáticamente.
    if [ ! -d "$ENV_DIR" ]; then
        echo -e "${YELLOW}[!] Detectada instalación nueva. Iniciando configuración automática...${NC}"
        setup_termux_proot
        enter_ubuntu
        create_alias
        echo -e "${GREEN}[+] ¡Configuración inicial completada!${NC}"
        echo ""
    fi

    # ✅ Bucle infinito para mantener el menú activo
    while true; do
        show_menu
        read -p "Opción: " opt
        case $opt in
            1) setup_termux_proot; enter_ubuntu; create_alias ;;
            2)
                read -p "Modelo (1-4): " model
                [[ -n "${MODEL_URLS[$model]}" ]] && download_model "$model" && generate_chat_script "$model" || echo -e "${RED}Inválido.${NC}"
                ;;
            3)
                proot-distro login ubuntu -- bash -c "
                    if [ -f \"$ENV_DIR/bin/activate\" ]; then
                        source \"$ENV_DIR/bin/activate\" && cd \"$SCRIPT_PATH\" && [ -f chatbot.py ] && python3 chatbot.py
                    else
                        echo -e \"${RED}Ejecuta opción 1 y 2 primero.${NC}\"
                    fi
                "
                ;;
            4) backup_to_github ;;
            5) request_github_token ;;
            6) [ -f "$TOKEN_FILE" ] && rm -f "$TOKEN_FILE" && echo -e "${GREEN}Token eliminado.${NC}" || echo -e "${YELLOW}No existe.${NC}" ;;
            7) echo -e "${GREEN}👋 ¡Hasta pronto!${NC}"; exit 0 ;;
            8) show_agent_templates_menu ;;
            *) echo -e "${RED}Opción inválida.${NC}" ;;
        esac
        read -p "Enter para continuar..." dummy
    done
}

main
