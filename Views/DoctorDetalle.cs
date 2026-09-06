namespace app_02.Views;

public sealed class DoctorDetalle
{
    public int Id { get; set; }
    public string Doctor { get; set; } = string.Empty;
    public int IdEspecialidad { get; set; }
    public string Especialidad { get; set; } = string.Empty;
    public int IdCiudad { get; set; }
    public string Ciudad { get; set; } = string.Empty;
}
