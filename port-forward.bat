@echo off
echo Starting port-forwards for ArgoCD and Jenkins...

REM Kill existing port-forwards
taskkill /f /im kubectl.exe 2>nul

REM Start ArgoCD port-forward
start "ArgoCD Port-Forward" cmd /k "kubectl port-forward svc/argocd-server -n argocd 8080:443 --address=0.0.0.0"

REM Wait a moment
timeout /t 2 /nobreak >nul

REM Start Jenkins port-forward  
start "Jenkins Port-Forward" cmd /k "kubectl port-forward svc/jenkins -n jenkins 8081:8080 --address=0.0.0.0"

echo Port-forwards started:
echo ArgoCD: https://localhost:8080
echo Jenkins: http://localhost:8081
echo.
echo Close the command windows to stop port-forwards
pause