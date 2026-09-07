using app_02.Data;
using app_02.DTO;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace app_02.Controllers;

[ApiController]
[Route("api/medicity/distribuida")]
public sealed class MedicityController(AppDbContext context) : ControllerBase
{
    private readonly AppDbContext _context = context;

    // VISTA 1: consulta distribuida general.
    [HttpGet("vistas/general")]
    public async Task<IActionResult> GetVistaGeneral(
        CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _context.ConsultaGeneral
                .AsNoTracking()
                .OrderBy(x => x.Num)
                .ToListAsync(cancellationToken));
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // VISTA 2: permite comprobar el resultado de sp_InsertarDoctor.
    [HttpGet("vistas/doctores")]
    public async Task<IActionResult> GetVistaDoctores(
        CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _context.Doctores
                .AsNoTracking()
                .OrderBy(x => x.Id)
                .ToListAsync(cancellationToken));
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // Un doctor por identificador.
    [HttpGet("vistas/doctores/{id:int}")]
    public async Task<IActionResult> GetDoctorPorId(
        int id, CancellationToken cancellationToken)
    {
        try
        {
            var doctor = await _context.Doctores
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

            return doctor is null
                ? NoEncontrado("doctor", id, "Sitio B")
                : Ok(doctor);
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // VISTA 3: permite comprobar el resultado de sp_ActualizarCitaMedica.
    [HttpGet("vistas/citas")]
    public async Task<IActionResult> GetVistaCitas(
        CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _context.Citas
                .AsNoTracking()
                .OrderBy(x => x.FechaHora)
                .ToListAsync(cancellationToken));
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // Una cita medica por identificador.
    [HttpGet("vistas/citas/{id:int}")]
    public async Task<IActionResult> GetCitaPorId(
        int id, CancellationToken cancellationToken)
    {
        try
        {
            var cita = await _context.Citas
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.IdCita == id, cancellationToken);

            return cita is null
                ? NoEncontrado("cita medica", id, "Sitio A")
                : Ok(cita);
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // Diagnosticos distribuidos, con filtros opcionales.
    [HttpGet("vistas/diagnosticos")]
    public async Task<IActionResult> GetVistaDiagnosticos(
        [FromQuery] int? idCita,
        [FromQuery] string? texto,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var consulta = _context.Diagnosticos.AsNoTracking();

            if (idCita is > 0)
            {
                consulta = consulta.Where(x => x.IdCita == idCita);
            }

            if (!string.IsNullOrWhiteSpace(texto))
            {
                var patron = $"%{texto.Trim()}%";
                consulta = consulta.Where(x =>
                    EF.Functions.Like(x.NombreDiagnostico, patron) ||
                    EF.Functions.Like(x.Descripcion, patron) ||
                    EF.Functions.Like(x.Tratamiento, patron) ||
                    EF.Functions.Like(x.Paciente, patron) ||
                    EF.Functions.Like(x.Doctor, patron));
            }

            return Ok(await consulta
                .OrderBy(x => x.IdDiagnostico)
                .ToListAsync(cancellationToken));
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // Un diagnostico por identificador.
    [HttpGet("vistas/diagnosticos/{id:int}")]
    public async Task<IActionResult> GetDiagnosticoPorId(
        int id, CancellationToken cancellationToken)
    {
        try
        {
            var diagnostico = await _context.Diagnosticos
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.IdDiagnostico == id, cancellationToken);

            return diagnostico is null
                ? NoEncontrado("diagnostico", id, "Sitio B")
                : Ok(diagnostico);
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // Catalogo de ciudades del Sitio A. Entrega los identificadores que
    // necesita el formulario de creacion de doctores.
    [HttpGet("vistas/ciudades")]
    public async Task<IActionResult> GetVistaCiudades(
        CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _context.Ciudades
                .AsNoTracking()
                .OrderBy(x => x.Nombre)
                .ToListAsync(cancellationToken));
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // Catalogo de especialidades del Sitio B.
    [HttpGet("vistas/especialidades")]
    public async Task<IActionResult> GetVistaEspecialidades(
        CancellationToken cancellationToken)
    {
        try
        {
            return Ok(await _context.Especialidades
                .AsNoTracking()
                .OrderBy(x => x.Nombre)
                .ToListAsync(cancellationToken));
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // PROCESO DEL PROFESOR 1: CREATE distribuido en DOCTOR_SB.
    [HttpPost("procesos/doctores/crear")]
    public async Task<IActionResult> CrearDoctor(
        DoctorCrearDto doctor, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_InsertarDoctor
                    @NOMBRE = {doctor.Nombre},
                    @ID_ESPECIALIDAD = {doctor.IdEspecialidad},
                    @ID_CIUDAD = {doctor.IdCiudad}", cancellationToken);

            return StatusCode(StatusCodes.Status201Created,
                new { mensaje = "Doctor registrado correctamente en Sitio B." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // PROCESO DEL PROFESOR 2: UPDATE local en CITA_MEDICA_SA.
    [HttpPut("procesos/citas/{id:int}/actualizar")]
    public async Task<IActionResult> ActualizarCita(
        int id, UpdateCitasDto cita, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_ActualizarCitaMedica
                    @ID = {id},
                    @ID_PACIENTE = {cita.IdPaciente},
                    @ID_DOCTOR = {cita.IdDoctor},
                    @FECHAHORA = {cita.FechaHora}", cancellationToken);

            return Ok(new { mensaje = "Cita medica actualizada correctamente en Sitio A." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // PROCESO PROPIO 1: CREATE distribuido en DIAGNOSTICO_SB.
    [HttpPost("procesos/diagnosticos/crear")]
    public async Task<IActionResult> CrearDiagnostico(
        DiagnosticoCrearDto diagnostico, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_InsertarDiagnostico
                    @ID_CITA = {diagnostico.IdCita},
                    @NOMBRE = {diagnostico.Nombre},
                    @DESCRIPCION = {diagnostico.Descripcion},
                    @TRATAMIENTO = {diagnostico.Tratamiento}", cancellationToken);

            return StatusCode(StatusCodes.Status201Created,
                new { mensaje = "Diagnostico registrado correctamente en Sitio B." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // PROCESO PROPIO 2: UPDATE distribuido en DIAGNOSTICO_SB.
    [HttpPut("procesos/diagnosticos/{id:int}/actualizar")]
    public async Task<IActionResult> ActualizarDiagnostico(
        int id, DiagnosticoActualizarDto diagnostico,
        CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_ActualizarDiagnostico
                    @ID = {id},
                    @ID_CITA = {diagnostico.IdCita},
                    @NOMBRE = {diagnostico.Nombre},
                    @DESCRIPCION = {diagnostico.Descripcion},
                    @TRATAMIENTO = {diagnostico.Tratamiento}", cancellationToken);

            return Ok(new { mensaje = "Diagnostico actualizado correctamente en Sitio B." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    private ObjectResult NoEncontrado(string entidad, int id, string sitio) =>
        StatusCode(StatusCodes.Status404NotFound, new
        {
            mensaje = $"No existe un registro de {entidad} con ID {id}.",
            sitio,
            sugerencia = "Consulte primero el listado correspondiente."
        });

    // Traduce los errores de SQL Server a respuestas HTTP entendibles.
    // Evita que una caida del Linked Server o una vista sin crear
    // terminen como un HTTP 500 sin explicacion.
    private ObjectResult SqlFailure(SqlException exception)
    {
        var (status, sugerencia) = exception.Number switch
        {
            // THROW de los procedimientos: el registro no existe.
            50011 or 50021 or 50301 or 50302 =>
                (StatusCodes.Status404NotFound, null as string),

            // THROW de los procedimientos: datos invalidos del cliente.
            >= 50001 and <= 50399 =>
                (StatusCodes.Status400BadRequest, null as string),

            // La vista o el procedimiento todavia no existe en MEDICITY_A.
            208 or 2812 => (StatusCodes.Status503ServiceUnavailable,
                "Ejecute database/03_OBJETOS_7_ENDPOINTS.sql y " +
                "database/04_VISTAS_ADICIONALES.sql en MEDICITY_A."),

            // El Linked Server no existe o no esta configurado.
            7202 or 7411 or 7415 or 7416 => (StatusCodes.Status503ServiceUnavailable,
                "Revise LS_SITIO_B con EXEC master.dbo.sp_testlinkedserver N'LS_SITIO_B'."),

            // Una de las dos instancias no responde, rechaza el login o
            // corta la conexion. El mensaje original indica cual fue.
            53 or -2 or 4060 or 10054 or 11001 or 18456 or 7303 or 7391 or 7399 =>
                (StatusCodes.Status503ServiceUnavailable,
                "Revise la conexion SQL: contrasena de sa, Tailscale y los " +
                "puertos 1440 (Sitio A) y 1441 (Sitio B)."),

            _ => (StatusCodes.Status400BadRequest, null as string)
        };

        return StatusCode(status, new
        {
            mensaje = exception.Message.Trim(),
            numeroSql = exception.Number,
            sitio = status == StatusCodes.Status503ServiceUnavailable
                ? "Comunicacion SQL distribuida"
                : "Sitio A",
            sugerencia
        });
    }
}
