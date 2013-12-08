/*
// set_nmi_vec.c
// 2013, rok.krajnc@gmail.com
// sets vector address for nmi
*/

#define NMI_VEC_ADR 0x0000007c
#define NMI_VEC_VAL 0x00a0000c

int main()
{
  (*(unsigned int*)(NMI_VEC_ADR)) = NMI_VEC_VAL;
}

