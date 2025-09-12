# 🤖 IA Local en Termux para Android (Z Fold 4 y superiores)

> **Ejecuta modelos de lenguaje como Mistral, TinyLlama o Phi-2 directamente en tu móvil — sin internet, sin root, sin servidor.**

✅ Compatible con **Samsung Galaxy Z Fold 4, 5, S23/S24 Ultra, y cualquier Android con 8GB+ RAM.**

---

## 🚀 Instalación (1 solo comando)

Abre **Termux** (instálalo desde [F-Droid](https://f-droid.org/en/packages/com.termux/ )) y ejecuta:

```bash
curl -sL https://raw.githubusercontent.com/txurtxil/termux-ia-local/main/install.sh  | bash
```

> ⚠️ No uses la versión de Termux de la Play Store — puede fallar. Usa siempre la de F-Droid.

---

## 🎮 Menú interactivo

Tras instalar, se abre un menú simple y responsive:

```
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
```

---

## 🤖 Plantillas de IA (Agentes en Segundo Plano)

¡Transforma tu terminal en un asistente proactivo! Elige una plantilla y tu IA trabajará para ti en segundo plano.

**Cómo usarlo:**
1.  En el menú principal, selecciona la opción `8) Configurar Agentes de IA (Plantillas)`.
2.  Elige la plantilla que desees.
3.  ¡Listo! El agente se instalará y comenzará a funcionar automáticamente.

**Plantillas Disponibles:**
*   **🧠 Terminal Pro:** Tu asistente personal. Analiza tu historial y te da sugerencias inteligentes al abrir la terminal.
*   **🧹 Auto-Organizador de Archivos:** Escanea tu carpeta de descargas y organiza automáticamente tus archivos por tipo (imágenes, documentos, etc.).
*   **📊 Analista de Red y Ancho de Banda:** Monitorea tu consumo de datos móviles y te alerta si estás cerca de superar tu límite.
*   **🛡️ Guardián de Seguridad:** Escanea las aplicaciones instaladas y te alerta si alguna tiene permisos potencialmente peligrosos.
*   **🤖 Generador de Scripts Automáticos:** Crea scripts Bash personalizados basados en tus necesidades. Ejecútalo manualmente con `ia-advanced-scripter`.

> 💡 Todos los agentes usan el modelo Mistral-7B Q3 para un equilibrio perfecto entre inteligencia y rendimiento. Solo se ejecutan cuando la batería está por encima del 20%.

---

## ▶️ Cómo usar el chatbot

1. Elige opción `2` y descarga un modelo (recomendado: `3` Mistral Q3 para equilibrio).
2. Elige opción `3` para iniciar el chat.
3. ¡Pregunta lo que quieras!

> 💡 Usa `ia-chat` en cualquier momento para volver al chat.

---

## 🔄 Backup a GitHub

1. Opción `5`: Ingresa tu token de GitHub.
2. Opción `4`: Sube automáticamente `install.sh` y `README.md` con versión y fecha.

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

> **Hecho con ❤️ para devs móviles — Versión generada: 2025-09-12 14:02:03**
