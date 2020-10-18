;
; WWW.FPGAArcade.COM
;
; REPLAY Retro Gaming Platform
; No Emulation No Compromise
;
; Replay.card - P96 RTG driver for the REPLAY Amiga core
; Copyright (C) FPGAArcade community
;
; Contributors : Jakub Bednarski, Mike Johnson, Jim Drew, Erik Hemming, Nicolas Hamel
;
; This software is licensed under LPGLv2.1 ; see LICENSE file
;
;

PSSO_BoardInfo_RegisterBase = 0
PSSO_BoardInfo_MemoryBase = 4
PSSO_BoardInfo_MemoryIOBase = 8
PSSO_BoardInfo_MemorySize = 12
PSSO_BoardInfo_BoardName = 16
PSSO_BoardInfo_VBIName = 20
PSSO_BoardInfo_CardBase = 52
PSSO_BoardInfo_ChipBase = 56
PSSO_BoardInfo_ExecBase = 60
PSSO_BoardInfo_UtilBase = 64
PSSO_BoardInfo_HardInterrupt = 68
PSSO_BoardInfo_SoftInterrupt = 90
PSSO_BoardInfo_BoardLock = 112
PSSO_BoardInfo_ResolutionsList = 158
PSSO_BoardInfo_BoardType = 170
PSSO_BoardInfo_PaletteChipType = 174
PSSO_BoardInfo_GraphicsControllerType = 178
PSSO_BoardInfo_MoniSwitch = 182
PSSO_BoardInfo_BitsPerCannon = 184
PSSO_BoardInfo_Flags = 186
PSSO_BoardInfo_SoftSpriteFlags = 190
PSSO_BoardInfo_ChipFlags = 192
PSSO_BoardInfo_CardFlags = 194
PSSO_BoardInfo_BoardNum = 198
PSSO_BoardInfo_RGBFormats = 200
PSSO_BoardInfo_MaxHorValue = 202
PSSO_BoardInfo_MaxVerValue = 212
PSSO_BoardInfo_MaxHorResolution = 222
PSSO_BoardInfo_MaxVerResolution = 232
PSSO_BoardInfo_MaxMemorySize = 242
PSSO_BoardInfo_MaxChunkSize = 246
PSSO_BoardInfo_MemoryClock = 250
PSSO_BoardInfo_PixelClockCount = 254
PSSO_BoardInfo_AllocCardMem = 274
PSSO_BoardInfo_FreeCardMem = 278
PSSO_BoardInfo_SetSwitch = 282
PSSO_BoardInfo_SetColorArray = 286
PSSO_BoardInfo_SetDAC = 290
PSSO_BoardInfo_SetGC = 294
PSSO_BoardInfo_SetPanning = 298
PSSO_BoardInfo_CalculateBytesPerRow = 302
PSSO_BoardInfo_CalculateMemory = 306
PSSO_BoardInfo_GetCompatibleFormats = 310
PSSO_BoardInfo_SetDisplay = 314
PSSO_BoardInfo_ResolvePixelClock = 318
PSSO_BoardInfo_GetPixelClock = 322
PSSO_BoardInfo_SetClock = 326
PSSO_BoardInfo_SetMemoryMode = 330
PSSO_BoardInfo_SetWriteMask = 334
PSSO_BoardInfo_SetClearMask = 338
PSSO_BoardInfo_SetReadPlane = 342
PSSO_BoardInfo_WaitVerticalSync = 346
PSSO_BoardInfo_SetInterrupt = 350
PSSO_BoardInfo_WaitBlitter = 354
PSSO_BoardInfo_ScrollPlanar = 358
PSSO_BoardInfo_ScrollPlanarDefault = 362
PSSO_BoardInfo_UpdatePlanar = 366
PSSO_BoardInfo_UpdatePlanarDefault = 370
PSSO_BoardInfo_BlitPlanar2Chunky = 374
PSSO_BoardInfo_BlitPlanar2ChunkyDefault = 378
PSSO_BoardInfo_FillRect = 382
PSSO_BoardInfo_FillRectDefault = 386
PSSO_BoardInfo_InvertRect = 390
PSSO_BoardInfo_InvertRectDefault = 394
PSSO_BoardInfo_BlitRect = 398
PSSO_BoardInfo_BlitRectDefault = 402
PSSO_BoardInfo_BlitTemplate = 406
PSSO_BoardInfo_BlitTemplateDefault = 410
PSSO_BoardInfo_BlitPattern = 414
PSSO_BoardInfo_BlitPatternDefault = 418
PSSO_BoardInfo_DrawLine = 422
PSSO_BoardInfo_DrawLineDefault = 426
PSSO_BoardInfo_BlitRectNoMaskComplete = 430
PSSO_BoardInfo_BlitRectNoMaskCompleteDefault = 434
PSSO_BoardInfo_BlitPlanar2Direct = 438
PSSO_BoardInfo_BlitPlanar2DirectDefault = 442
PSSO_BoardInfo_Reserved0 = 446
PSSO_BoardInfo_Reserved0Default = 450
PSSO_BoardInfo_Reserved1 = 454
PSSO_BoardInfo_Reserved1Default = 458
PSSO_BoardInfo_Reserved2 = 462
PSSO_BoardInfo_Reserved2Default = 466
PSSO_BoardInfo_Reserved3 = 470
PSSO_BoardInfo_Reserved3Default = 474
PSSO_BoardInfo_Reserved4 = 478
PSSO_BoardInfo_Reserved4Default = 482
PSSO_BoardInfo_Reserved5 = 486
PSSO_BoardInfo_Reserved5Default = 490
PSSO_BoardInfo_SetDPMSLevel = 494
PSSO_BoardInfo_ResetChip = 498
PSSO_BoardInfo_GetFeatureAttrs = 502
PSSO_BoardInfo_AllocBitMap = 506
PSSO_BoardInfo_FreeBitMap = 510
PSSO_BoardInfo_GetBitMapAttr = 514
PSSO_BoardInfo_SetSprite = 518
PSSO_BoardInfo_SetSpritePosition = 522
PSSO_BoardInfo_SetSpriteImage = 526
PSSO_BoardInfo_SetSpriteColor = 530
PSSO_BoardInfo_CreateFeature = 534
PSSO_BoardInfo_SetFeatureAttrs = 538
PSSO_BoardInfo_DeleteFeature = 542
PSSO_BoardInfo_SpecialFeatures = 546
PSSO_BoardInfo_ModeInfo = 558
PSSO_BoardInfo_RGBFormat = 562
PSSO_BoardInfo_XOffset = 566
PSSO_BoardInfo_YOffset = 568
PSSO_BoardInfo_Depth = 570
PSSO_BoardInfo_ClearMask = 571
PSSO_BoardInfo_Border = 572
PSSO_BoardInfo_Mask = 574
PSSO_BoardInfo_CLUT = 578
PSSO_BoardInfo_ViewPort = 1346
PSSO_BoardInfo_VisibleBitMap = 1350
PSSO_BoardInfo_BitMapExtra = 1354
PSSO_BoardInfo_BitMapList = 1358
PSSO_BoardInfo_MemList = 1370
PSSO_BoardInfo_MouseX = 1382
PSSO_BoardInfo_MouseY = 1384
PSSO_BoardInfo_MouseWidth = 1386
PSSO_BoardInfo_MouseHeight = 1387
PSSO_BoardInfo_MouseXOffset = 1388
PSSO_BoardInfo_MouseYOffset = 1389
PSSO_BoardInfo_MouseImage = 1390
PSSO_BoardInfo_MousePens = 1394
PSSO_BoardInfo_MouseRect = 1398
PSSO_BoardInfo_MouseChunky = 1406
PSSO_BoardInfo_MouseRendered = 1410
PSSO_BoardInfo_MouseSaveBuffer = 1414
PSSO_BoardInfo_ChipData = 1418
PSSO_BoardInfo_CardData = 1482
PSSO_BoardInfo_MemorySpaceBase = 1546
PSSO_BoardInfo_MemorySpaceSize = 1550
PSSO_BoardInfo_DoubleBufferList = 1554
PSSO_BoardInfo_SyncTime = 1558
PSSO_BoardInfo_SyncPeriod = 1562
PSSO_BoardInfo_SoftVBlankPort = 1570
PSSO_BoardInfo_SizeOf = 1604

CardData_HTotal = PSSO_BoardInfo_CardData+0
CardData_HSStart = PSSO_BoardInfo_CardData+2
CardData_HSStop = PSSO_BoardInfo_CardData+4
CardData_HBStop = PSSO_BoardInfo_CardData+6
CardData_VTotal = PSSO_BoardInfo_CardData+8
CardData_VSStart = PSSO_BoardInfo_CardData+10
CardData_VSStop = PSSO_BoardInfo_CardData+12
CardData_VBStop = PSSO_BoardInfo_CardData+14
CardData_Beamcon0 = PSSO_BoardInfo_CardData+16
CardData_Control = PSSO_BoardInfo_CardData+18
CardData_HWTrigger = PSSO_BoardInfo_CardData+20

