@echo off
mkdir "c:\Users\Davide\Documents\Proyectos Flutter\biomarcad\docs\images" 2>nul
copy "C:\Users\Davide\.gemini\antigravity\brain\8f939b17-ed25-4950-908b-02b1cbf51177\uploaded_image_1768167729898.png" "c:\Users\Davide\Documents\Proyectos Flutter\biomarcad\docs\images\dashboard_design.png"
copy "C:\Users\Davide\.gemini\antigravity\brain\8f939b17-ed25-4950-908b-02b1cbf51177\measure_screen_mockup_1768258502179.png" "c:\Users\Davide\Documents\Proyectos Flutter\biomarcad\docs\images\measure_screen.png"
copy "C:\Users\Davide\.gemini\antigravity\brain\8f939b17-ed25-4950-908b-02b1cbf51177\heart_rate_scan_mockup_1768258513867.png" "c:\Users\Davide\Documents\Proyectos Flutter\biomarcad\docs\images\scan_screen.png"
echo Imagenes copiadas a docs/images exitosamente.
pause
del "%~f0"
