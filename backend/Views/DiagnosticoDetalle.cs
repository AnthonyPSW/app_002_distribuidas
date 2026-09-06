namespace app_02.Views;

public sealed class DiagnosticoDetalle
{
    public int IdDiagnostico { get; set; }
    public int IdCita { get; set; }
    public int IdPaciente { get; set; }
    public string Paciente { get; set; } = string.Empty;
    public int IdDoctor { get; set; }
    public string Doctor { get; set; } = string.Empty;
    public DateTime FechaHora { get; set; }
    public string? Diagnostico { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    public string? Tratamiento { get; set; }
}
