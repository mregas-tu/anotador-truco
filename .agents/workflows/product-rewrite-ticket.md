---
description: Transforma un ticket coloquial en una especificación técnica y de producto de alto nivel
---

# Product Rewrite Ticket Workflow

## Role Orchestration
Para ejecutar este workflow, el sistema debe actuar como un **Product Engineer Senior**, orquestando capacidades de Product Management, Arquitectura de Sistemas y Desarrollo Backend.

## Steps

### 1. Discovery & Context
* **Action:** Analizar el ticket original del usuario.
* **Output:** Definición clara del problema y contexto de negocio.
* *Required Capability:* `Product Manager`

### 2. Product Solution & UX
* **Action:** Definir la solución funcional, casos de uso y criterios de aceptación.
* **Output:** Lista de features y reglas de negocio.
* *Required Capability:* `Product Manager`, `UI/UX Designer`

### 3. Technical Strategy
* **Action:** Diseñar la arquitectura de la solución. Incluir diagramas Mermaid (secuencia/ER) si hay cambios en DB o flujos complejos.
* **Output:** Plan técnico detallado.
* *Required Capability:* `Architecture`, `NestJS Expert`

### 4. Implementation Breakdown
* **Action:** Desglosar el ticket en tareas atómicas (sub-tickets).
* **Output:** Checklist de tareas técnicas y funcionales.
* *Required Capability:* `Engineering Manager`

---

## Capabilities Mapping (Injected at Runtime)
Este flujo requiere acceso a las siguientes definiciones de conocimiento:
- `Product Toolkit`: Para metodologías de criterios de aceptación.
- `Architecture Specs`: Para patrones de diseño y estándares de LegalPulse.
- `NestJS/Drizzle Standards`: Para la generación de código y esquemas.