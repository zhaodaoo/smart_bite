/// MFRC522 Register addresses
class MFRC522Registers {
  // Command and status registers
  static const int commandReg = 0x01;
  static const int comIEnReg = 0x02;
  static const int divIEnReg = 0x03;
  static const int comIrqReg = 0x04;
  static const int divIrqReg = 0x05;
  static const int errorReg = 0x06;
  static const int status1Reg = 0x07;
  static const int status2Reg = 0x08;
  static const int fifoDataReg = 0x09;
  static const int fifoLevelReg = 0x0A;
  static const int waterLevelReg = 0x0B;
  static const int controlReg = 0x0C;
  static const int bitFramingReg = 0x0D;
  static const int collReg = 0x0E;

  // Command registers
  static const int modeReg = 0x11;
  static const int txModeReg = 0x12;
  static const int rxModeReg = 0x13;
  static const int txControlReg = 0x14;
  static const int txASKReg = 0x15;
  static const int txSelReg = 0x16;
  static const int rxSelReg = 0x17;
  static const int rxThresholdReg = 0x18;
  static const int demodReg = 0x19;
  static const int mifareTxReg = 0x1C;
  static const int mifareRxReg = 0x1D;
  static const int serialSpeedReg = 0x1F;

  // Configuration registers
  static const int crcResultRegMSB = 0x21;
  static const int crcResultRegLSB = 0x22;
  static const int modWidthReg = 0x24;
  static const int rfCfgReg = 0x26;
  static const int gsnReg = 0x27;
  static const int cwGsPReg = 0x28;
  static const int modGsPReg = 0x29;
  static const int tModeReg = 0x2A;
  static const int tPrescalerReg = 0x2B;
  static const int tReloadRegH = 0x2C;
  static const int tReloadRegL = 0x2D;
  static const int tCounterValRegH = 0x2E;
  static const int tCounterValRegL = 0x2F;

  // Test registers
  static const int testSel1Reg = 0x31;
  static const int testSel2Reg = 0x32;
  static const int testPinEnReg = 0x33;
  static const int testPinValueReg = 0x34;
  static const int testBusReg = 0x35;
  static const int autoTestReg = 0x36;
  static const int versionReg = 0x37;
  static const int analogTestReg = 0x38;
  static const int testDAC1Reg = 0x39;
  static const int testDAC2Reg = 0x3A;
  static const int testADCReg = 0x3B;
}

/// MFRC522 Commands
class MFRC522Commands {
  static const int idle = 0x00;
  static const int mem = 0x01;
  static const int generateRandomId = 0x02;
  static const int calcCRC = 0x03;
  static const int transmit = 0x04;
  static const int noCmdChange = 0x07;
  static const int receive = 0x08;
  static const int transceive = 0x0C;
  static const int mfAuthent = 0x0E;
  static const int softReset = 0x0F;
}

/// PICC Commands
class PICCCommands {
  static const int reqidl = 0x26;
  static const int reqall = 0x52;
  static const int anticoll = 0x93;
  static const int select = 0x93;
  static const int authent1A = 0x60;
  static const int authent1B = 0x61;
  static const int read = 0x30;
  static const int write = 0xA0;
  static const int decrement = 0xC0;
  static const int increment = 0xC1;
  static const int restore = 0xC2;
  static const int transfer = 0xB0;
  static const int halt = 0x50;
}

/// Status codes
class MFRC522Status {
  static const int ok = 0;
  static const int error = 1;
  static const int notag = 2;
  static const int collision = 3;
}
