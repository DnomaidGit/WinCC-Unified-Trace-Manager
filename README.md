# WinCC Unified Trace Manager Web

Aplicación web local para controlar RTILtraceTool.exe y abrir RTILtraceViewer.exe desde Windows PowerShell 5.1, sin Python.

1. Extraer el ZIP.
2. Ejecutar `Iniciar.bat`.
3. Abrir `http://localhost:8080` si no se abre automáticamente.
4. Introducir la IP del panel y pulsar **Conectar**.

La carpeta por defecto es `C:\Program Files\Siemens\Automation\WinCCUnified\bin`. Ambos ejecutables deben existir allí. Los mensajes de TraceReceiver se guardan en `receiver-out.log` y `receiver-error.log` y se muestran en la interfaz. El receptor puede almacenar temporalmente mensajes en búfer, por lo que su aparición inmediata depende de la herramienta Siemens. El servidor escucha solo en localhost. No exponerlo a Internet.

Corrección principal: `ReadBody` recibe `$ctx.Request`, no `$ctx`. La configuración se guarda en `settings.json`.


## V8
- Lectura de receiver-out.log y receiver-error.log con FileShare.ReadWrite para evitar errores cuando Siemens escribe simultáneamente.
- El servidor HTTP permanece operativo ante bloqueos transitorios de los registros.


## V9: Desconectar
El botón Desconectar solicita la parada con `RTILtraceTool.exe -mode stop -process PID` y comprueba que termina el proceso iniciado por la aplicación. Si no se detiene en el plazo establecido, muestra un error y no indica que esté desconectado. No cierra TraceViewer ni detiene otros receptores.


V10: eliminado el botón Desconectar de la interfaz. La gestión interna del proceso se mantiene.
