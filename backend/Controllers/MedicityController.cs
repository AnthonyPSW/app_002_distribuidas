using app_02.Data;
using app_02.DTO;
using app_02.Views;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace app_02.Controllers;

[ApiController]
[Route("api/medicity/distribuida")]
public sealed class MedicityController(AppDbContext context) : ControllerBase
{
    private readonly AppDbContext _context = context;

    [HttpGet("health")]
    public async Task<IActionResult> Health(CancellationToken cancellationToken)
    {
        var databaseAvailable = await _context.Database.CanConnectAsync(cancellationToken);
        return databaseAvailable
            ? Ok(new { estado = "ok", baseDatos = "MEDICITY_A" })
            : StatusCode(StatusCodes.Status503ServiceUnavailable,
                new { mensaje = "No se pudo conectar con MEDICITY_A." });
    }

    [HttpGet("view")]
    [HttpGet("resumen")]
    public async Task<ActionResult<IReadOnlyList<ConsultaGeneral>>> GetResumen(
        CancellationToken cancellationToken)
    {
        var resultado = await _context.ConsultaGeneral
            .AsNoTracking()
            .OrderBy(x => x.Num)
            .ToListAsync(cancellationToken);

        return Ok(resultado);
    }

    [HttpGet("catalogos/ciudades")]
    public async Task<ActionResult<IReadOnlyList<CatalogoItem>>> GetCiudades(
        CancellationToken cancellationToken)
    {
        var resultado = await _context.Database
            .SqlQueryRaw<CatalogoItem>(
                "SELECT ID AS Id, NOMBRE AS Nombre FROM dbo.CIUDAD_SA ORDER BY NOMBRE")
            .ToListAsync(cancellationToken);

        return Ok(resultado);
    }

    [HttpGet("catalogos/pacientes")]
    public async Task<ActionResult<IReadOnlyList<CatalogoItem>>> GetPacientes(
        CancellationToken cancellationToken)
    {
        var resultado = await _context.Database
            .SqlQueryRaw<CatalogoItem>(
                "SELECT ID AS Id, NOMBRE AS Nombre FROM dbo.PACIENTE_SA ORDER BY NOMBRE")
            .ToListAsync(cancellationToken);

        return Ok(resultado);
    }

    [HttpGet("catalogos/especialidades")]
    public async Task<ActionResult<IReadOnlyList<CatalogoItem>>> GetEspecialidades(
        CancellationToken cancellationToken)
    {
        var resultado = await _context.Database
            .SqlQueryRaw<CatalogoItem>(
                "SELECT ID AS Id, NOMBRE AS Nombre " +
                "FROM [LS_SITIO_B].[MEDICITY_B].[dbo].[ESPECIALIDAD_SB] ORDER BY NOMBRE")
            .ToListAsync(cancellationToken);

        return Ok(resultado);
    }

    // CRUD DE DOCTORES
    [HttpGet("doctores")]
    public async Task<ActionResult<IReadOnlyList<DoctorDetalle>>> GetDoctores(
        CancellationToken cancellationToken)
    {
        return Ok(await _context.Doctores.AsNoTracking()
            .OrderBy(x => x.Id)
            .ToListAsync(cancellationToken));
    }

    [HttpGet("doctores/{id:int}")]
    public async Task<ActionResult<DoctorDetalle>> GetDoctor(
        int id, CancellationToken cancellationToken)
    {
        var doctor = await _context.Doctores.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

        return doctor is null
            ? NotFound(new { mensaje = "Doctor no encontrado." })
            : Ok(doctor);
    }

    [HttpPost("doctores")]
    [HttpPost("sp_doctor")]
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
                new { mensaje = "Doctor registrado correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    [HttpPut("doctores/{id:int}")]
    public async Task<IActionResult> ActualizarDoctor(
        int id, DoctorCrearDto doctor, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_ActualizarDoctor
                    @ID = {id},
                    @NOMBRE = {doctor.Nombre},
                    @ID_ESPECIALIDAD = {doctor.IdEspecialidad},
                    @ID_CIUDAD = {doctor.IdCiudad}", cancellationToken);

            return Ok(new { mensaje = "Doctor actualizado correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    [HttpDelete("doctores/{id:int}")]
    public async Task<IActionResult> EliminarDoctor(
        int id, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC dbo.sp_EliminarDoctor @ID = {id}", cancellationToken);

            return Ok(new { mensaje = "Doctor eliminado correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // CRUD DE CITAS MEDICAS
    [HttpGet("citas")]
    public async Task<ActionResult<IReadOnlyList<CitaMedicaDetalle>>> GetCitas(
        CancellationToken cancellationToken)
    {
        return Ok(await _context.Citas.AsNoTracking()
            .OrderBy(x => x.FechaHora)
            .ToListAsync(cancellationToken));
    }

    [HttpGet("citas/{id:int}")]
    public async Task<ActionResult<CitaMedicaDetalle>> GetCita(
        int id, CancellationToken cancellationToken)
    {
        var cita = await _context.Citas.AsNoTracking()
            .FirstOrDefaultAsync(x => x.IdCita == id, cancellationToken);

        return cita is null
            ? NotFound(new { mensaje = "Cita medica no encontrada." })
            : Ok(cita);
    }

    [HttpPost("citas")]
    public async Task<IActionResult> CrearCita(
        CitaCrearDto cita, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync($@"
                EXEC dbo.sp_InsertarCitaMedica
                    @ID_PACIENTE = {cita.IdPaciente},
                    @ID_DOCTOR = {cita.IdDoctor},
                    @FECHAHORA = {cita.FechaHora}", cancellationToken);

            return StatusCode(StatusCodes.Status201Created,
                new { mensaje = "Cita medica registrada correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    [HttpPut("citas/{id:int}")]
    [HttpPut("{id:int}")]
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

            return Ok(new { mensaje = "Cita medica actualizada correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    [HttpDelete("citas/{id:int}")]
    public async Task<IActionResult> EliminarCita(
        int id, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC dbo.sp_EliminarCitaMedica @ID = {id}", cancellationToken);

            return Ok(new { mensaje = "Cita medica eliminada correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    // CRUD DE DIAGNOSTICOS
    [HttpGet("diagnosticos")]
    public async Task<ActionResult<IReadOnlyList<DiagnosticoDetalle>>> GetDiagnosticos(
        CancellationToken cancellationToken)
    {
        return Ok(await _context.Diagnosticos.AsNoTracking()
            .OrderBy(x => x.IdDiagnostico)
            .ToListAsync(cancellationToken));
    }

    [HttpGet("diagnosticos/{id:int}")]
    public async Task<ActionResult<DiagnosticoDetalle>> GetDiagnostico(
        int id, CancellationToken cancellationToken)
    {
        var diagnostico = await _context.Diagnosticos.AsNoTracking()
            .FirstOrDefaultAsync(x => x.IdDiagnostico == id, cancellationToken);

        return diagnostico is null
            ? NotFound(new { mensaje = "Diagnostico no encontrado." })
            : Ok(diagnostico);
    }

    [HttpPost("diagnosticos")]
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
                new { mensaje = "Diagnostico registrado correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    [HttpPut("diagnosticos/{id:int}")]
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

            return Ok(new { mensaje = "Diagnostico actualizado correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    [HttpDelete("diagnosticos/{id:int}")]
    public async Task<IActionResult> EliminarDiagnostico(
        int id, CancellationToken cancellationToken)
    {
        try
        {
            await _context.Database.ExecuteSqlInterpolatedAsync(
                $"EXEC dbo.sp_EliminarDiagnostico @ID = {id}", cancellationToken);

            return Ok(new { mensaje = "Diagnostico eliminado correctamente." });
        }
        catch (SqlException ex)
        {
            return SqlFailure(ex);
        }
    }

    private ObjectResult SqlFailure(SqlException exception)
    {
        var status = exception.Number switch
        {
            50011 or 50021 or 50101 or 50104 or 50204 or 50301 or 50304
                => StatusCodes.Status404NotFound,
            50105 or 50205 => StatusCodes.Status409Conflict,
            _ => StatusCodes.Status400BadRequest
        };

        return StatusCode(status, new { mensaje = exception.Message });
    }
}
