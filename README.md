# Sistema de Gestión del Mundial de Fútbol ⚽

> Trabajo práctico correspondiente a la materia **Bases de Datos Aplicadas (3641)**  
> **Comisión:** 02-5600 (Viernes Tarde) — **Ingeniería en Informática**  
> Universidad Nacional de La Matanza (UNLaM)

---

## 📋 Descripción General

Este proyecto implementa un sistema integral de base de datos relacional para la gestión operativa y comercial de la Copa Mundial de la FIFA 2026 en Microsoft SQL Server. 

El modelo abarca:
* **Módulo 1 (Administración):** Sedes, selecciones, cupo de 48 selecciones, cuerpos técnicos con límite de 1 DT, y planteles oficiales de hasta 26 jugadores y reemplazo de ultimo momento en las convocatorias.
* **Módulo 2 (Partidos y Cambios):** Programación con cálculo automático de hora UTC según huso horario de la sede, esquemas tácticos, alineaciones y control de sustituciones  (máximo 5 cambios en hasta 3 ventanas).
* **Módulo 3 (Goles, Tarjetas y Árbitros):** ABM de árbitros e idiomas, designación con control estricto de nacionalidad neutral, registro de goles con actualización automática de marcador, y sanciones disciplinarias acumulativas.
* **Módulo 4 (Publicidad y Exhibición Comercial):** Generación de 4 slots perimetrales por partido y manejo en el orden de prioridad para asignar piezas publicitarias segun PBI per cápita del mercado, horario Prime Time y costo.

---

## 🛠️ Tecnologías y Entorno
* **Motor:** Microsoft SQL Server 2022 o superior
* **Herramienta de Gestión:** SQL Server Management Studio (SSMS)
* **Collation Oficial:** `Modern_Spanish_CI_AS`
* **Estándar:** T-SQL puro, tipado estricto, sin cursores en operaciones transaccionales, manejo de errores vía `THROW`.

---

## 📁 Estructura del Proyecto

```text
├── docs/
│   ├── der/                          
│   │   ├── der_v1.1.jpg              
│   │   └── der_v1.1_dbdiagram.txt    
│   └── Instalación-y-Configuración.pdf
├── scripts/
│   ├── 01_creacion_base_de_datos.sql
│   ├── 02_creacion_esquemas.sql
│   ├── 03_creacion_tablas.sql
│   ├── 04_sp_administracion.sql
│   ├── 05_sp_partidos_y_cambios.sql
│   ├── 06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   ├── 07_sp_publicidad.sql.sql
│   ├── 00_datos_semilla.sql
│   ├── test_04_administracion.sql
│   ├── test_05_partidos_y_cambios.sql
│   ├── test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
│   ├── test_07_publicidad.sql.sql
│   └── test_partido_inaugural.sql
├── .gitignore
└── README.md
```

---

## 🚀 Guía de Instalación y Creación desde Cero

Para levantar la base de datos de manera limpia, abrir **SQL Server Management Studio (SSMS)** y ejecutar los scripts ubicados en la carpeta `scripts/` respetando el siguiente **orden secuencial de dependencias**:

### Paso 1: Infraestructura de Base de Datos y Esquemas
1. **`01_creacion_base_de_datos.sql`**: Crea la base de datos `Mundial2026` con el collation institucional.
2. **`02_creacion_esquemas.sql`**: Crea los 4 esquemas de seguridad lógica (`administracion`, `partido`, `arbitraje`, `publicidad`).
3. **`03_creacion_tablas.sql`**: Elimina versiones previas en orden inverso de dependencias y crea las 25 tablas relacionales con sus claves primarias, foráneas, restricciones `CHECK` y valores `UNIQUE`.

### Paso 2: Compilación de Lógica de Negocio (Stored Procedures)
Ejecutar los procedimientos almacenados de cada módulo:
4. **`04_sp_administracion.sql`** (Módulo 1: Países, Clubes, Sedes, Selecciones, Jugadores, Convocatorias y Reemplazo por Lesión).
5. **`05_sp_partidos_y_cambios.sql`** (Módulo 2: Partidos con cálculo UTC, Formaciones, Alineaciones titulares y Sustituciones).
6. **`06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`** (Módulo 3: Árbitros, Designación neutral, Registro de Goles y Control Disciplinario).
7. **`07_sp_publicidad.sql.sql`** (Módulo 4: Anunciantes, Campañas, Piezas y Algoritmo de Asignación Publicitaria).

### Paso 3: Carga de Datos Semilla
8. **`00_datos_semilla.sql`**: Puebla los datos maestros del torneo (sedes oficiales, selecciones de prueba, planteles iniciales con dorsales, árbitros internacionales, campañas comerciales y partidos iniciales).

---

##  🧪 Guía de Testing y Validación

Cada módulo cuenta con su propio script de prueba unitaria independiente, más un script integral final que simula el partido inaugural del torneo.

> [!IMPORTANT]
> **Mecánica de Evaluación y Pruebas:**
> Para garantizar que cada prueba se evalúe exactamente sobre el estado base oficial y de forma 100% reproducible, **antes de ejecutar cualquiera de los scripts de test se debe ejecutar previamente `00_datos_semilla.sql`**.
>
> **Flujo mecánico recomendado para cada prueba:**
> 1. Ejecutar `00_datos_semilla.sql` (resetea los datos maestros y reinicia los contadores de identidad a cero).
> 2. Ejecutar el script de test que se desee evaluar (`test_04...`, `test_05...`, `test_06...`, `test_07...` o `test_partido_inaugural.sql`).
> 3. Visualizar los resultados y estados de éxito en las pestañas *Resultados* y *Mensajes* de SSMS.
> 4. Repetir el ciclo en caso de querer ejecutar otro script de test

| Script de Prueba | Módulo / Alcance Evaluado | Casos de Prueba Incluidos |
| :--- | :--- | :--- |
| **`test_04_administracion.sql`** | Módulo 1 (Administración) | • Alta, modificación y baja de entidades maestras (País, Club, Sede).<br>• Validación de cupo de 26 jugadores y bloqueo al jugador 27.<br>• Reemplazo por lesión previa con herencia de dorsal.<br> |
| **`test_05_partidos_y_cambios.sql`** | Módulo 2 (Partidos) | • Creación de partido con cálculo de huso horario a UTC.<br>• Bloqueo de solapamiento de partidos en misma sede y horario.<br>• Control de máximo 11 titulares por formación táctica.<br>• Control de sustituciones: máximo 5 cambios y bloqueo de 4ta ventana. |
| **`test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql`** | Módulo 3 (Goles y Disciplina) | • Alta y asignación de árbitro con validación de nacionalidad neutral.<br>• Expulsión con tarjeta roja y generación de suspensión de oficio.<br>• Registro de goles con impacto directo en el marcador del partido. |
| **`test_07_publicidad.sql.sql`** | Módulo 4 (Publicidad) | • Generación de los 4 slots perimetrales por encuentro.<br>• Alta de anunciantes y campañas comerciales con rango de fechas.<br>• Ejecución del algoritmo de asignación evaluando selecciones en cancha, PBI y montos facturados. |
| **`test_partido_inaugural.sql`** | **Integración Total (Módulos 1, 2, 3 y 4)** | **Simulación oficial del Partido Inaugural (México 2 - 0 Sudáfrica):**<br>• Acreditación de selecciones y DTs oficiales.<br>• Reemplazo por lesión previo con herencia de dorsal.<br>• Programación en Estadio Azteca con cálculo UTC y generación de slots.<br>• Terna arbitral neutral (Wilton Sampaio - Brasil).<br>• 11 titulares y cambios con ventanas IFAB en el 2do tiempo.<br>• Tarjetas disciplinarias y goles oficiales (Quiñones y Jiménez).<br>• Asignación comercial en paneles perimetrales del estadio.<br>|


---



## 👥 Integrantes del Grupo

* **Aleman Flores, Matias Osvaldo**
* **Gamarra Bravo, Sidney Maribel**
* **Perreira, Carlos Manuel**
* **Villa, Brenda**
