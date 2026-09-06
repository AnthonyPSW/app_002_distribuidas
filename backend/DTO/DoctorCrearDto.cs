using System.ComponentModel.DataAnnotations;

namespace app_02.DTO;

public sealed class DoctorCrearDto
{
    [Required, StringLength(100, MinimumLength = 2)]
    public string Nombre { get; set; } = string.Empty;

    [Range(1, int.MaxValue)]
    public int IdEspecialidad { get; set; }

    [Range(1, int.MaxValue)]
    public int IdCiudad { get; set; }
}
