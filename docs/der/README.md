# Diagrama Entidad-Relación (DER)

Este directorio contiene el modelo conceptual y relacional del sistema.

---

## Historial de Versiones

### Versión 1.0 - 02/10/2026
* **Alcance cubierto:**
  * Países, husos horarios y sedes/estadios.
  * Selecciones, planteles, cuerpos técnicos y convocatorias.
  * Estructura de partidos por fases, esquemas tácticos y alineaciones.
  * Registro de eventos: goles, sustituciones y tarjetas.
  * Designaciones arbitrales e idiomas 
  * Suspensiones y cumplimiento de sanciones.
  * Pauta, espacios publicitarios y exhibición de contenido.

### Versión 1.0 - 07/10/2026
  * Se reincorpora ID_Seleccion en Formacion_Partido para optimizar la trazabilidad del plantel y delegar la validación de localía/visita al Stored Procedure.

  * Se incorpora el atributo orden int en la tabla Fase_Torneo para establecer la jerarquía cronológica de las etapas y optimizar las validaciones de fases eliminatorias en los Stored Procedures.