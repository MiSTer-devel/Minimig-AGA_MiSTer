unsigned long SwapBBBB(unsigned long i)
{
  return ((i&0x00ff0000)>>8) | ((i&0xff000000)>>24) | ((i&0x000000ff)<<24) | ((i&0x0000ff00)<<8);
}

unsigned int SwapBB(unsigned int i)
{
  return (i&0xffff0000) | ((i&0x000000ff)<<8) | ((i&0x0000ff00)>>8);
}

unsigned long SwapWW(unsigned long i)
{
  //return ((i&0x0000ffff)<<16) | ((i&0xffff0000)>>16);
  return ((i<<16) | (i>>16));
}
