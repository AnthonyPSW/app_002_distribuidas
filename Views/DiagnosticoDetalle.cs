namespace app_02.Views;

/// <summary>
/// Fila de <c>vw_DiagnosticoDetalle</c>. Une el diagnostico del
/// Sitio B con su cita, paciente y ciudad del Sitio A.
/// </summary>
public sealed class DiagnosticoDetalle
{
    public int IdDiagnostico { get; set; }
    public int IdCita { get; set; }
    public string NombreDiagnostico { get; set; } = string.Empty;
    public string Descripcion { get; set; } = string.Empty;
    public string Tratamiento { get; set; } = string.Empty;
    public DateTime FechaHora { get; set; }
    public int IdPaciente { get; set; }
    public string Paciente { get; set; } = string.Empty;
    public string CiudadPaciente { get; set; } = string.Empty;
    public int IdDoctor { get; set; }
    public string Doctor { get; set; } = string.Empty;
    public string Especialidad { get; set; } = string.Empty;
}
