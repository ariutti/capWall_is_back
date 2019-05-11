/***************************************************
	This is a library for the MPR121 12-Channel Capacitive Sensor

	Designed specifically to work with the MPR121 breakout from Adafruit
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

/*
* TODO: add methods for:
* 1. setting Rising/Releasing/Touched value for ELEPROX (manipulate 0x36 through 0x40);
* 2. reading touch status fro the ELEPROX (register 0x01 bit 5);
* 3. reading Over Current Flags (register 0x01 bit 7);
* 3bis. reading the Out Of Range R egisters (0x02 and 0x03). This will be useful
* to check if the Autocalibration has worked! See Application Note AN3889
* for more details;
* 4. Modify 'fiteredData' and 'baseLineData' in order for these methods to
* read data for the ELEPROX refisters 0x1C and 0x2A respectively;
* 5. Modify the 'touched' method in order to read also data about the
* ELEPROX electrode;
* 6. add an end method (we already have a 'begin' method);
* 7. Add methods for setting individual CDC/CDT per elecrode;
* 8. Add new mwthods for setting the autoconfiguration (see AN3889);
* 9. CL (register 0x5E higher bits) and BVA (them must be the same);
* 10. modify the 'runMode' method in order for the user to select how many
*	electrodes he wants to use (see datasheet pg 16);
* 11. methods for acting on the AutoConfiuration AutoREconfiguration function
* In other words manipulate registers from 0x7C t 0x7F;
*/

#ifndef LIMULO_MPR121_H
#define LIMULO_MPR121_H

#if (ARDUINO >= 100)
 #include "Arduino.h"
#else
 #include "WProgram.h"
#endif
#include <Wire.h>

// The default I2C address
#define MPR121_I2CADDR_DEFAULT 0x5A

#define MPR121_TOUCHSTATUS_L 0x00
#define MPR121_TOUCHSTATUS_H 0x01

#define MPR121_OOR          0x02

#define MPR121_FILTDATA_0L  0x04
#define MPR121_FILTDATA_0H  0x05
#define MPR121_BASELINE_0   0x1E

/* RISING */
#define MPR121_MHDR         0x2B
#define MPR121_NHDR         0x2C
#define MPR121_NCLR         0x2D
#define MPR121_FDLR         0x2E

/* FALLING */
#define MPR121_MHDF         0x2F
#define MPR121_NHDF         0x30
#define MPR121_NCLF         0x31
#define MPR121_FDLF         0x32

/* TOUCHED */
#define MPR121_NHDT         0x33
#define MPR121_NCLT         0x34
#define MPR121_FDLT         0x35

#define MPR121_TOUCHTH_0    0x41
#define MPR121_RELEASETH_0	0x42

#define MPR121_DEBOUNCE     0x5B

#define MPR121_CONFIG1      0x5C  // FFI | CDC
#define MPR121_CONFIG2      0x5D  // CDT | SFI | ESI

#define MPR121_ECR          0x5E  // CL | ELEPROX_EN | ELE_EN

#define MPR121_CHARGECURR_0 0x5F
#define MPR121_CHARGETIME_1 0x6C

#define MPR121_AUTOCONFIG1  0x7B  // FFI | RETRY | BVA | ARE | ACE
#define MPR121_AUTOCONFIG2  0x7C  // SCTS | // | // | // | OORIE | ARFIE | ACFIE

#define MPR121_USL          0x7D
#define MPR121_LSL          0x7E
#define MPR121_TL           0x7F

#define MPR121_GPIODIR      0x76
#define MPR121_GPIOEN       0x77
#define MPR121_GPIOSET      0x78
#define MPR121_GPIOCLR      0x79
#define MPR121_GPIOTOGGLE   0x7A

#define MPR121_SOFTRESET    0x80

// NOTE: BVA and CL must be the same (DataSheet pg 16);
// NOTE: FFI (in 0x5C) and FFI (in 0x7B) must be the same for correct
// autoconfiguration and autoREconfiguration operations (see DataSheet pg 17);

class Limulo_MPR121
{
	public:
		// Hardware I2C
		Limulo_MPR121(void);

		boolean begin(uint8_t i2caddr = MPR121_I2CADDR_DEFAULT);

		void reset(void);

		void stopMode();
		void runMode();

		void setUSL(uint8_t usl);
		void setLSL(uint8_t lsl);
		void setTL(uint8_t tl);

		void setFFI(uint8_t ffi);
		void setSFI(uint8_t sfi);
		void setESI(uint8_t esi);
		void setFFI_SFI_ESI(uint8_t ffi, uint8_t sfi, uint8_t esi);

		void setGlobalCDC(uint8_t cdc);
		void setGlobalCDT(uint8_t cdt);

		void setDebounces(uint8_t touch, uint8_t release);

		void setFalling(uint8_t mhd, uint8_t nhd, uint8_t ncl, uint8_t fdl);
		void setRising(uint8_t mhd, uint8_t nhd, uint8_t ncl, uint8_t fdl);
		void setTouched(uint8_t nhd, uint8_t ncl, uint8_t fdl);

		void setMHD(uint8_t rising, uint8_t falling);
		void setNHD(uint8_t rising, uint8_t falling, uint8_t touched);
		void setNCL(uint8_t rising, uint8_t falling, uint8_t touched);
		void setFDL(uint8_t rising, uint8_t falling, uint8_t touched);

		void setThresholds(uint8_t touch, uint8_t release);

		uint16_t baselineData(uint8_t t);
		uint16_t filteredData(uint8_t t);
		uint16_t touched(void);

		uint16_t getOOR(void); //added 19/02/2018

		uint8_t readRegister8(uint8_t reg);
		uint16_t readRegister16(uint8_t reg);
		void writeRegister(uint8_t reg, uint8_t value);

		void printRegisters( void );
		void printRegister( uint8_t reg );

		void printCDC( void );
		void printCDT( void );
		void printOOR( void );

	private:
		uint8_t _i2caddr;
		uint8_t _usl;
		uint8_t _tl;
		uint8_t _lsl;
		uint8_t _touchth;
		uint8_t _releaseth;

		uint8_t _ffi;
		uint8_t _sfi;
		uint8_t _esi;

		// falling
		uint8_t _mhdf;
		uint8_t _nhdf;
		uint8_t _nclf;
		uint8_t _fdlf;

		// rising
		uint8_t _mhdr;
		uint8_t _nhdr;
		uint8_t _nclr;
		uint8_t _fdlr;

		// touched
		uint8_t _nhdt;
		uint8_t _nclt;
		uint8_t _fdlt;

		uint8_t _debouncet;
		uint8_t _debouncer;

		uint8_t _bva_cl;
		uint8_t _retry;
		uint8_t _ace;
		uint8_t _are;
};

#endif // LIMULO_MPR121_H
