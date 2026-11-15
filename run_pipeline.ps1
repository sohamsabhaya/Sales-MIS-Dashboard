# Windows PowerShell Automation Script for Sales MIS Analytics
param (
    [string]$Command = "pipeline"
)

$PythonExe = ".\venv\Scripts\python.exe"
if (-not (Test-Path $PythonExe)) {
    $PythonExe = "python"
}

switch ($Command.ToLower()) {
    "inspect" {
        Write-Host ">>> Inspecting & Profiling Raw Data..." -ForegroundColor Cyan
        & $PythonExe python/inspect_data.py
    }
    "targets" {
        Write-Host ">>> Generating Synthetic Targets (Seed 42)..." -ForegroundColor Cyan
        & $PythonExe python/generate_targets.py
    }
    "clean" {
        Write-Host ">>> Running Data Cleaning & Quarantine..." -ForegroundColor Cyan
        & $PythonExe python/clean_data.py
    }
    "rfm" {
        Write-Host ">>> Running RFM Segmentation & Cohort Analysis..." -ForegroundColor Cyan
        & $PythonExe python/rfm_analytics.py
    }
    "report" {
        Write-Host ">>> Generating Executive Excel MIS Workbook..." -ForegroundColor Cyan
        & $PythonExe python/generate_mis_report.py --period 2018-06 --source csv
    }
    "pipeline" {
        Write-Host ">>> Executing End-to-End Master Pipeline..." -ForegroundColor Cyan
        & $PythonExe python/run_pipeline.py
    }
    default {
        Write-Host "Available options: inspect, targets, clean, rfm, report, pipeline" -ForegroundColor Yellow
    }
}

