# Analizador de Bitcoins


Herramienta desarrollada en Bash para explorar e inspeccionar transacciones y direcciones de la red Bitcoin directamente desde la terminal. Utiliza la API oficial de Blockchain.info en formato JSON para extraer datos precisos, realizar conversiones en tiempo real a dólares (USD) y presentar la información en tablas dinámicas estructuradas.

![Menú de Ayuda](ruta/a/tu/imagen_ayuda.png)
*(Reemplaza esta ruta con la imagen de tu panel de ayuda `./btcAnalyzer.sh -h`)*

## Características Principales

* **Exploración en tiempo real:** Lista las últimas transacciones no confirmadas (mempool) de la red Bitcoin.
* **Inspección de Hashes:** Desglosa transacciones individuales mostrando las direcciones de entrada, direcciones de salida y los valores exactos transferidos.
* **Análisis de Billeteras (Addresses):** Consulta el historial completo de una dirección específica (total recibido, total enviado, saldo actual y número de transacciones).
* **Conversión a Moneda Fiat:** Realiza cálculos matemáticos al vuelo usando `awk` para mostrar equivalencias exactas en dólares (USD) según la cotización actual del mercado.
* **Interfaz de Terminal:** Formateo automático de tablas con la herramienta `column` y código de colores para facilitar la lectura.

## Requisitos

El script hace uso de utilidades nativas de Linux y requiere un procesador JSON ligero. Asegúrate de tener instalados los siguientes paquetes en tu sistema:

* `curl` (para peticiones web)
* `jq` (para parseo de estructuras JSON)
* `awk` y `sed` (para cálculos de punto flotante y formateo de cadenas)

En distribuciones basadas en Debian/Kali Linux, puedes instalar las dependencias faltantes con:
```bash
sudo apt-get install curl jq awk sed
