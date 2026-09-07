namespace app_02.Views;

public sealed class ConsultaGeneral
{
    public long Num { get; set; }
    public int IdCita { get; set; }
    public int? IdDiagnostico { get; set; }
    public string? NombreDiagnostico { get; set; }
    public string Paciente { get; set; } = string.Empty;
    public DateTime FechaNacimiento { get; set; }
    public string? Direccion { get; set; }
    public string CiudadPaciente { get; set; } = string.Empty;
    public string Doctor { get; set; } = string.Empty;
    public string CiudadDoctor { get; set; } = string.Empty;
    public string Especialidad { get; set; } = string.Empty;
    public DateTime FechaHora { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    public string Tratamiento { get; set; } = string.Empty;
}
