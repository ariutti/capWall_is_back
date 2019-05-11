/***************************************************
	This is a library for the MPR121 I2C 12-chan Capacitive Sensor

	Designed specifically to work with the MPR121 sensor from Adafruit
	----> https://www.adafruit.com/products/1982

	These sensors use I2C to communicate, 2+ pins are required to
	interface
	Adafruit invests time and resources providing this open source code,
	please support Adafruit and open-source hardware by purchasing
	products from Adafruit!

	Written by Limor Fried/Ladyada for Adafruit Industries.
	BSD license, all text above must be included in any redistribution

	Modified by limulo.net (http://www.limulo.net)
 ****************************************************/

#include "Limulo_MPR121.h"

Limulo_MPR121::Limulo_MPR121()
{
}

boolean Limulo_MPR121::begin(uint8_t i2caddr)
{
	Wire.begin();

	_i2caddr = i2caddr;

	// SOFT RESET: all registers are set to default values
	// except for registers 0x5C (CONFIG1) and 0x5D (CONFIG2).
	// See datasheet pg.11 and pg.19
	writeRegister(MPR121_SOFTRESET, 0x63);
	delay(1);
	//printRegisters();
	uint8_t c = readRegister8(MPR121_CONFIG2);
	if (c != 0x24) return false;

	// PRELIMINARY SETTINGS ******************************
	// Set some default value
	_ffi = 0x00;
	_sfi = 0x00;
	_esi = 0x00;
	_bva_cl = 0x02;
	_retry = 0x01;
	_are = 0x01;
	_ace = 0x01;
	// Targets Level (see AN3889 pg 7) *******************
	// These values are set supposing the supply voltage
	// 'Vcc' is 3,3V.
	// ULS = ((Vcc-0.7)/Vcc)*256 = 201 (= 806 in 10bit)
	// LSL = USL * 0.65 = 180 (= 726 in 10bit)
	// TL  = USL * 0.9 = 130 (= 524 in 10bit)
	_usl = 201;
	_tl  = 180;
	_lsl = 130;
	_touchth = 150;
	_releaseth = 50;

	// falling
	_mhdf = 1;
	_nhdf = 1;
	_nclf = 2;
	_fdlf = 1;

	// rising
	_mhdr = 1;
	_nhdr = 8;
	_nclr = 1;
	_fdlr = 0;

	// touched
	_nhdt = 1;
	_nclt = 0;
	_fdlt = 0;

	// debounce
	_debouncet = 0x07;
	_debouncer = 0x01;

	reset();

	return true;
}

void Limulo_MPR121::reset(void)
{
	//soft reset: all registers are set to default values
	writeRegister(MPR121_SOFTRESET, 0x63);

	delay(1);

	stopMode();

	// These two register are left untouched after the 'soft reset'
	writeRegister(MPR121_CONFIG1, (_ffi<<6) | 0x10 ); // FFI=6, global CDC is 16uA (default)
	writeRegister(MPR121_CONFIG2, 0x20 | (_sfi<<3) | _esi); // global CDT is 0.5uS (default)

	// Autoconfiguration:
	// FFI=6 (must match FFI in 0x5C) | RETRY=2 times | BVA (must match CL in ECR (0x5E)) | ARE enabled | ACE enabled
	writeRegister(MPR121_AUTOCONFIG1, (_ffi<<6) | (_retry<<4) | (_bva_cl<<2) | (_are<<1) | _ace );
	writeRegister(MPR121_AUTOCONFIG2, 0x00); // SCTS=0 OORIE,ARFIE,ACFIE=0

	// Set targets:
	writeRegister(MPR121_USL, _usl);
	writeRegister(MPR121_TL,  _tl );
	writeRegister(MPR121_LSL, _lsl);

	// Falling: filtered data lower than baseline values
	writeRegister(MPR121_MHDF, _mhdf); // (0 - 63)
	writeRegister(MPR121_NHDF, _nhdf); // (0 - 63)
	writeRegister(MPR121_NCLF, _nclf); //
	writeRegister(MPR121_FDLF, _fdlf); //

	// Rising: filtered data greater than baseline values
	writeRegister(MPR121_MHDR, _mhdr); // maximum half-delta (0 - 63)
	writeRegister(MPR121_NHDR, _nhdr);	// noise half-delta (0 - 63)
	writeRegister(MPR121_NCLR, _nclr);	// noise count limit
	writeRegister(MPR121_FDLR, _fdlr);	// filter delay count

	// Touched: when electrode is in touch status
	writeRegister(MPR121_NHDT, _nhdt); // (0 - 63)
	writeRegister(MPR121_NCLT, _nclt); //
	writeRegister(MPR121_FDLT, _fdlt); //

	// Debounce:
	// 2 touch/release detections before Status changes (EFI x SFI x 2 (ms) delay)
	writeRegister(MPR121_DEBOUNCE, (_debouncer<<4) | _debouncet);

	for (uint8_t i=0; i<12; i++)
	{
		writeRegister(MPR121_TOUCHTH_0 + 2*i, _touchth);
		writeRegister(MPR121_RELEASETH_0 + 2*i, _releaseth);
	}

	delay(5);
	runMode();

}

/*******************************************************************************
* MODEs
* This methods are also involved in setting the CL (calibration Lock) value
* which is responsible on how the baseline tracking will work.
* (See DataSheet pg 11 and pg 16)
*******************************************************************************/
void Limulo_MPR121::stopMode( void )
{
	// enter STOP MODE
	writeRegister(MPR121_ECR, (_bva_cl<<6) | 0x00); // CL=11 (BVA must match)
}

void Limulo_MPR121::runMode( void )
{
	// exit STOP MODE, enter RUN MODE
	writeRegister(MPR121_ECR, (_bva_cl<<6) | 0x0F); //CL=11 (BVA must match) | ELEPROX disable / all ele enabled
}



/*******************************************************************************
* AUTOCONFIGURATION
* (See Application Note AN3889 pg.7 for more details).
*******************************************************************************/
void Limulo_MPR121::setUSL(uint8_t usl)
{
	_usl = usl;
	stopMode();
	writeRegister(MPR121_USL, _usl);
	runMode();
}

void Limulo_MPR121::setLSL(uint8_t lsl)
{
	_lsl = lsl;
	stopMode();
	writeRegister(MPR121_LSL, _lsl);
	runMode();
}

void Limulo_MPR121::setTL(uint8_t tl)
{
	_tl = tl;
	stopMode();
	writeRegister(MPR121_TL, _tl);
	runMode();
}


/*******************************************************************************
* CAPACITANCE SETTINGS (1st and 2nd filter)
* (See Application Note AN3890 for more details).
*******************************************************************************/
void Limulo_MPR121::setFFI(uint8_t ffi)
{
	_ffi = ffi & 0x03;
	uint8_t tmp_cdc = readRegister8( MPR121_CONFIG1 );
	tmp_cdc = tmp_cdc & 0x3F;
	uint8_t tmp_retry_bvacl_are_ace = readRegister8( MPR121_AUTOCONFIG1 );
	tmp_retry_bvacl_are_ace = tmp_retry_bvacl_are_ace & 0x3F;

	stopMode();
	writeRegister(MPR121_CONFIG1, (_ffi<<6) | tmp_cdc );
	writeRegister(MPR121_AUTOCONFIG1, (_ffi<<6) | tmp_retry_bvacl_are_ace );
	runMode();
}

void Limulo_MPR121::setSFI(uint8_t sfi)
{
	_sfi = sfi & 0x03;
	uint8_t cdt_esi = readRegister8( MPR121_CONFIG2 );
	cdt_esi = cdt_esi & 0xE7;

	stopMode();
	writeRegister(MPR121_CONFIG2, cdt_esi | (_sfi<<3) );
	runMode();
}

void Limulo_MPR121::setESI(uint8_t esi)
{
	_esi = esi & 0x07;
	uint8_t cdt_sfi = readRegister8( MPR121_CONFIG2 );
	cdt_sfi = cdt_sfi & 0xF8;

	stopMode();
	writeRegister(MPR121_CONFIG2, cdt_sfi | _esi );
	runMode();
}

// a single method to set them all!
void Limulo_MPR121::setFFI_SFI_ESI(uint8_t ffi, uint8_t sfi, uint8_t esi)
{
	setFFI(ffi);
	setESI(esi);
	setSFI(sfi);
}

/*******************************************************************************
* CDC and CDT (Charge/Discharge Current and Time)
* Methods to set:
* 1. Charge/Discharge Current (CDC): values between 0 and 63 are allowed;
* 2. Charge/Discharge Time (CDT): values between 0 and 7 are allowed;
* These values can be set both globally and per-electrode.
* (See Application Note AN3889).
*******************************************************************************/
void Limulo_MPR121::setGlobalCDC(uint8_t cdc)
{
	uint8_t _cdc = cdc & 0x3F;
	_cdc = _cdc << 0;
	uint8_t ffi = readRegister8( MPR121_CONFIG1 );
	ffi = ffi & 0xC0;

	stopMode();
	writeRegister(MPR121_CONFIG1, ffi | _cdc );
	runMode();
}

void Limulo_MPR121::setGlobalCDT(uint8_t cdt)
{
	uint8_t _cdt = cdt & 0x07;
	_cdt = _cdt << 5;
	uint8_t sfi_esi = readRegister8( MPR121_CONFIG2 );
	sfi_esi = sfi_esi & 0x1F;

	stopMode();
	writeRegister(MPR121_CONFIG2, sfi_esi | _cdt );
	runMode();
}

/*******************************************************************************
* SET DEBOUNCE
* Set how many additional readings must be
* perceived before detecting a touch or release
*******************************************************************************/
void Limulo_MPR121::setDebounces(uint8_t touch, uint8_t release)
{
	_debouncet = touch & 0x07;
	_debouncer = release & 0x07;

	stopMode();
	writeRegister( MPR121_DEBOUNCE, (_debouncer<<4) | _debouncet );
	runMode();
}

/*******************************************************************************
* Section below is dedicated to the modification of registers
* relates to the Baseline System (see AN3891 document).
* There are different ways we can accomplish this:
* 1. we can set registers indicating the Rising/Falling/Touched phase;
* 2. we can set them explicitly for all the phases;
*******************************************************************************/
// Falling phase: when filtered data are lower than baseline values.
void Limulo_MPR121::setFalling(uint8_t mhd, uint8_t nhd, uint8_t ncl, uint8_t fdl)
{
	_mhdf = mhd & 0x3F;
	_nhdf = nhd & 0x3F;
	_nclf = ncl;
	_fdlf = fdl;

	stopMode();
	writeRegister(MPR121_MHDF, _mhdf);	// maximum half-delta (0 - 63)
	writeRegister(MPR121_NHDF, _nhdf);	// noise half-delta (0 - 63)
	writeRegister(MPR121_NCLF, _nclf);	// noise count limit
	writeRegister(MPR121_FDLF, _fdlf);	// filter delay count
	runMode();
}


// Rising phase: when filtered data greater than baseline values.
void Limulo_MPR121::setRising(uint8_t mhd, uint8_t nhd, uint8_t ncl, uint8_t fdl)
{
	_mhdr = mhd & 0x3F;
	_nhdr = nhd & 0x3F;
	_nclr = ncl;
	_fdlr = fdl;

	stopMode();
	writeRegister(MPR121_MHDR, _mhdr);	// maximum half-delta (0 - 63)
	writeRegister(MPR121_NHDR, _nhdr);	// noise half-delta (0 - 63)
	writeRegister(MPR121_NCLR, _nclr);	// noise count limit
	writeRegister(MPR121_FDLR, _fdlr);	// filter delay count
	runMode();
}

// Touched phase: when electrodes are in touch status.
void Limulo_MPR121::setTouched(uint8_t nhd, uint8_t ncl, uint8_t fdl)
{
	_nhdt = nhd & 0x3F;
	_nclt = ncl;
	_fdlt = fdl;

	stopMode();
	writeRegister(MPR121_NHDT, _nhdt);	// noise half-delta (0 - 63)
	writeRegister(MPR121_NCLT, _nclt);	// noise count limit
	writeRegister(MPR121_FDLT, _fdlt);	// filter delay count
	runMode();
}


void Limulo_MPR121::setMHD(uint8_t rising, uint8_t falling)
{
	_mhdr = rising;
	_mhdf = falling;
	stopMode();
	writeRegister(MPR121_MHDR, _mhdr);
	writeRegister(MPR121_MHDF, _mhdf);
	runMode();
}

void Limulo_MPR121::setNHD(uint8_t rising, uint8_t falling, uint8_t touched)
{
	_nhdr = rising;
	_nhdf = falling;
	_nhdt = touched;
	stopMode();
	writeRegister(MPR121_NHDR, _nhdr);
	writeRegister(MPR121_NHDF, _nhdf);
	writeRegister(MPR121_NHDT, _nhdt);
	runMode();
}

void Limulo_MPR121::setNCL(uint8_t rising, uint8_t falling, uint8_t touched)
{
	_nclr = rising;
	_nclf = falling;
	_nclt = touched;
	stopMode();
	writeRegister(MPR121_NCLR, _nclr);
	writeRegister(MPR121_NCLF, _nclf);
	writeRegister(MPR121_NCLT, _nclt);
	runMode();
}

void Limulo_MPR121::setFDL(uint8_t rising, uint8_t falling, uint8_t touched)
{
	_fdlr = rising;
	_fdlf = falling;
	_fdlt = touched;
	stopMode();
	writeRegister(MPR121_FDLR, _fdlr);
	writeRegister(MPR121_FDLF, _fdlf);
	writeRegister(MPR121_FDLT, _fdlt);
	runMode();
}

/*******************************************************************************
* TOUCH TH and RELEASE TH are values comprised between 0 and 255.
* These values are used to detect a touch and a release according to these formulae:
*
* 1. Touch condition   = (Baseline - Filtered Data) > Touch Th
* 2. Release condition = (Baseline - Filtered Data) < Release Th
*
* These values affect register between 0x41 - 0x5A.
* (See Technical Note AN3892 for more details).
*******************************************************************************/
void Limulo_MPR121::setThresholds(uint8_t touchth, uint8_t releaseth)
{
	_touchth = touchth;
	_releaseth = releaseth;

	stopMode();
	for (uint8_t i=0; i<12; i++)
	{
		writeRegister(MPR121_TOUCHTH_0 + 2*i, _touchth);
		writeRegister(MPR121_RELEASETH_0 + 2*i, _releaseth);
	}
	runMode();
}

/*******************************************************************************
* Section below shows methods for reading data from individual electrodes.
* Simply specify the number of the electrode you are interested in (a number
* between 0 and 11) in calling them.
*******************************************************************************/
uint16_t Limulo_MPR121::baselineData(uint8_t t)
{
	if (t > 12) return 0;
	uint16_t bl = readRegister8(MPR121_BASELINE_0 + t);
	return (bl << 2);
}


uint16_t Limulo_MPR121::filteredData(uint8_t t)
{
	if (t > 12) return 0;
	return readRegister16(MPR121_FILTDATA_0L + t*2);
}


/*******************************************************************************
* Below a method to read the first 2 registers where the status of all 12+1
* electrodes are saved (0x00 and 0x01)
*******************************************************************************/
uint16_t Limulo_MPR121::touched(void)
{
	uint16_t t = readRegister16(MPR121_TOUCHSTATUS_L);
	return t & 0x1FFF;
}

/*******************************************************************************
* Below a method to read the third and fourth register
*  where the OOR information are stored.
*******************************************************************************/
uint16_t Limulo_MPR121::getOOR(void)
{
	uint16_t t = readRegister16(MPR121_OOR);
	return t & 0x1FFF;
}


/*******************************************************************************
* READ REGISTERS
*******************************************************************************/
uint8_t Limulo_MPR121::readRegister8(uint8_t reg)
{
	Wire.beginTransmission(_i2caddr);
	Wire.write(reg);
	Wire.endTransmission(false);
	while (Wire.requestFrom(_i2caddr, 1) != 1);
	return ( Wire.read());
}

uint16_t Limulo_MPR121::readRegister16(uint8_t reg)
{
	Wire.beginTransmission(_i2caddr);
	Wire.write(reg);
	Wire.endTransmission(false);
	while (Wire.requestFrom(_i2caddr, 2) != 2);
	uint16_t v = Wire.read();
	v |=  ((uint16_t) Wire.read()) << 8;
	return v;
}

/*******************************************************************************
* WRITE REGISTERS
*******************************************************************************/
// Writes 8-bits to the specified destination register
void Limulo_MPR121::writeRegister(uint8_t reg, uint8_t value)
{
	Wire.beginTransmission(_i2caddr);
	Wire.write((uint8_t)reg);
	Wire.write((uint8_t)(value));
	Wire.endTransmission();
}

/*******************************************************************************
* PRINT REGISTERS
* Serial communication must be opened first!
*******************************************************************************/
// print all registers for debug purposes.
void Limulo_MPR121::printRegisters( void )
{
	for (uint8_t i=0; i<0x80; i++)
	{
		Serial.print("$"); Serial.print(i, HEX);
		Serial.print(": 0x"); Serial.println(readRegister8(i), HEX);
	}
}

// print out a specific register
void Limulo_MPR121::printRegister(uint8_t reg)
{
	Serial.print("$"); Serial.print(reg, HEX);
	Serial.print(": 0x"); Serial.println(readRegister8(reg), HEX);
}

// print CDC in a more readable way
void Limulo_MPR121::printCDC( void )
{// print CDC / CDT
	uint8_t cdc = readRegister8( MPR121_CONFIG1 ) & 0x3F;
	Serial.print("CDC: ");
	Serial.print(cdc, DEC);
	Serial.println(" uA;");
}

// print CDT in a more readable way
void Limulo_MPR121::printCDT( void )
{
	uint8_t cdt = readRegister8(MPR121_CONFIG2) & 0xE0;
	cdt = cdt >> 5;
	signed int exp = cdt - 2;
	float time = (float) pow(2, exp);
	Serial.print("CDT: ");
	Serial.print( time, DEC);
	Serial.println(" uS;");
}

// print OOR
void Limulo_MPR121::printOOR( void )
{
	uint8_t oor1 = readRegister8(MPR121_OOR);
	uint8_t oor2 = readRegister8(MPR121_OOR+1) & 0x1F;

	Serial.print("$"); Serial.print(MPR121_OOR, HEX);
	Serial.print(": 0x"); Serial.print(oor1, HEX);
	Serial.print("\t");
	Serial.print("$"); Serial.print(MPR121_OOR+1, HEX);
	Serial.print(": 0x"); Serial.println(oor2, HEX);
}
