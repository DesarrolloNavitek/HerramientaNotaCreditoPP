SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
IF EXISTS (SELECT 1 FROM SYS.objects WHERE name = 'nvk_spEjecutaExplorarProntoPago' AND type = 'P')
DROP PROC dbo.nvk_spEjecutaExplorarProntoPago
GO
CREATE PROC dbo.nvk_spEjecutaExplorarProntoPago
@Empresa			char(5),
@Usuario			varchar(20)
AS
BEGIN
DECLARE
    @HoyDia INT = DAY(GETDATE()),
	@MesAnteriorInicio DATE = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)),
	@UltimoDiaMesAnterior INT,
	@FechaBase		DATE = GETDATE(),
	@FechaD			DATE,
    @FechaA			DATE,
    @DIAS    varchar(20) = 0

SET @UltimoDiaMesAnterior	= DAY(EOMONTH(@MesAnteriorInicio))

SET @FechaD					= DATEFROMPARTS(
    YEAR(@MesAnteriorInicio),
    MONTH(@MesAnteriorInicio),
    CASE WHEN @HoyDia > @UltimoDiaMesAnterior THEN @UltimoDiaMesAnterior ELSE @HoyDia END)

SET @FechaA					= @FechaBase

EXEC spNaviExploraProntoPago @Empresa,@Usuario,@FechaD, @FechaA,@DIAS

EXEC spNaviExploraProntoPagoActualizar  @Empresa

RETURN
END
--IF EXISTS (SELECT 1 FROM SYS.objects WHERE name = 'nvk_spEjecutaExplorarProntoPago' AND type = 'P')
--    DROP PROC dbo.nvk_spEjecutaExplorarProntoPago
--GO

--CREATE PROC dbo.nvk_spEjecutaExplorarProntoPago
--    @Empresa    CHAR(5),
--    @Usuario    VARCHAR(20)
--AS
--BEGIN
--    SET NOCOUNT ON;

--    DECLARE
--        @FechaBase  DATE = GETDATE(),
--        @FechaD     DATE,
--        @FechaA     DATE,
--        @DIAS       VARCHAR(20) = 0,
--        @RC         INT;

--    SET @FechaD = DATEFROMPARTS(YEAR(@FechaBase), MONTH(@FechaBase), 1);
--    SET @FechaA = EOMONTH(@FechaBase);

--    BEGIN TRY
     
--        EXEC @RC = spNaviExploraProntoPago @Empresa, @Usuario, @FechaD, @FechaA, @DIAS;

--        IF @RC <> 0 OR @RC IS NULL
--        BEGIN
--            RAISERROR('Error en spNaviExploraProntoPago, RC=%d', 16, 1, @RC);
--            RETURN -1;
--        END

--        EXEC @RC = spNaviExploraProntoPagoActualizar @Empresa;

--        IF @RC <> 0 OR @RC IS NULL
--        BEGIN
--            RAISERROR('Error en spNaviExploraProntoPagoActualizar, RC=%d', 16, 1, @RC);
--            RETURN -1;
--        END

--    END TRY
--    BEGIN CATCH
--        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
--        DECLARE @ErrProc NVARCHAR(200) = ISNULL(ERROR_PROCEDURE(), 'nvk_spEjecutaExplorarProntoPago');

--        RAISERROR('Error en %s: %s', 16, 1, @ErrProc, @ErrMsg);
--        RETURN -1;
--    END CATCH

--    RETURN 0;
--END