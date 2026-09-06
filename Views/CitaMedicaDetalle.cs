namespace app_02.Views;

public sealed class CitaMedicaDetalle
{
    public int IdCita { get; set; }
    public int IdPaciente { get; set; }
    public string Paciente { get; set; } = string.Empty;
    public int IdDoctor { get; set; }
    public string Doctor { get; set; } = string.Empty;
    public int IdEspecialidad { get; set; }
    public string Especialidad { get; set; } = string.Empty;
    public DateTime FechaHora { get; set; }
}
