# Caraxes

Caraxes is a prototype disaster intelligence and rescue coordination platform designed to assist authorities and first responders during natural disasters such as floods, earthquakes, cyclones, and landslides.

The platform combines citizen-reported information with AI-based infrastructure damage assessment to provide a clearer picture of the situation on the ground. By analyzing images and location data, Caraxes helps identify damaged infrastructure, prioritize incidents, and support rescue operations.

---
## Demo Videos

### Victim Interface Demo

https://github.com/user-attachments/assets/df811a70-93c6-4c58-aba9-c76131aba4fc

Demonstrates:
- User authentication
- Disaster reporting with image upload
- SOS request submission
- Safe zone recommendations
- Citizen-side disaster assistance workflow

---

### Rescuer Interface Demo

https://github.com/user-attachments/assets/0d74c6ea-332f-4680-945c-37ab40433513


Demonstrates:
- Incident monitoring dashboard
- Disaster map visualization
- Damage assessment results
- SOS request management
- Rescue coordination workflow
---

## Problem Statement

During disasters, obtaining accurate and timely information from affected areas is challenging. Authorities often rely on manual surveys, fragmented reports, and delayed assessments, which can slow down rescue and recovery efforts.

Caraxes aims to bridge this gap by combining citizen-generated reports with AI-powered damage assessment to enable faster and more informed decision-making.

---

## Features

### Citizen Reporting
- Upload photos of damaged infrastructure
- Submit SOS requests
- Share GPS location data
- Provide ground-level disaster information

### AI Damage Assessment
- Detect damaged roads, bridges, and buildings
- Assess damage severity
- Generate incident reports from uploaded images

### Rescue Coordination
- View reported incidents on a map
- Prioritize critical locations
- Access optimized rescue routes
- Monitor incoming SOS requests

### Disaster Dashboard
- Centralized incident monitoring
- Damage visualization
- Location-based reporting
- Rescue operation support

---

## How It Works

1. Citizens submit disaster reports through the mobile application.
2. Images and location data are sent to the backend.
3. AI models analyze uploaded images and identify infrastructure damage.
4. The system stores incident information and updates the disaster map.
5. Rescue teams can view incidents and receive route recommendations.
6. Authorities gain a consolidated view of the disaster situation.

---

## Tech Stack

### Frontend
- Flutter

### Backend
- Flask

### AI & Computer Vision
- PyTorch
- OpenCV
- YOLOv12
- SegFormer / U-Net

### Machine Learning & Algorithms
- XGBoost
- A* Search Algorithm

### Database & Storage
- Firebase Firestore
- Firebase Storage
- Firebase Authentication

### Maps & Geospatial
- OpenStreetMap


---

## Project Structure

```text
caraxes/
│
├── frontend/          # Flutter application
├── backend/           # Flask APIs and services
├── ai/                # AI models and inference
├── docs/              # Architecture diagrams and assets
└── README.md
```

---

## Prototype Scope

This repository contains the hackathon prototype developed during a limited-time sprint.

The current implementation focuses on demonstrating the core workflow of the platform:

- Citizen incident reporting
- SOS request submission
- Infrastructure damage detection
- Incident mapping and visualization
- Emergency route generation

The goal of the prototype is to validate the overall concept and demonstrate how citizen-generated information can be combined with AI-based analysis to support disaster response.

---

## Future Scope

The complete vision for Caraxes includes:

- Infrastructure failure prediction
- Dynamic safe-zone recommendation
- Multi-source data validation
- Offline-first communication support
- Disaster recovery simulation
- Real-time rescuer tracking
- Advanced resource allocation and prioritization

---

## Repository Status

⚠️ This project is currently a hackathon prototype and should be considered a proof of concept. Features, architecture, and workflows may evolve in future iterations.

---

## Team Caraxes

Built as part of a Smart India Hackathon internal hackathon.

