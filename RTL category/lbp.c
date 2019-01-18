#include "loadbmp.h"
#include <stdio.h>
#include <stdlib.h>
int main(void) {
    unsigned char *image=NULL;
    unsigned int xsize=0;
    unsigned int ysize=0;
    int i=0, j=0; 
    FILE *fp=NULL;
    FILE *fz=NULL;
    fp = fopen("./pixel4.dat", "wb");
	fz = fopen("./golden4.dat", "wb");

	int box[16384]={0} ;

    readbmp("2.bmp", &xsize, &ysize, &image);
    printf("res: %dx%d\n", xsize, ysize);
   for (i=ysize-1; i>=0; i--) {
        for (j=0; j<xsize; ++j) 
		{
		fprintf(fp, "%x\n",image[i*xsize+j]);
    }}
    for (i=ysize-2; i>0; i--) {
        for (j=1; j<xsize-1; j++) 
		{        //fprintf(fp, "%x\n", image[i*xsize+j]);
		if(image[i*xsize+j-129]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+32 ;
		if(image[i*xsize+j-128]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+64 ;
		if(image[i*xsize+j-127]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+128;
		if(image[i*xsize+j-1]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+8 ;
		if(image[i*xsize+j+1]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+16 ;
		if(image[i*xsize+j+127]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+1 ;
		if(image[i*xsize+j+128]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+2 ;
		if(image[i*xsize+j+129]>=image[i*xsize+j])
		box[i*xsize+j]=box[i*xsize+j]+4 ;
		}
    }
	

   for (i=ysize-1; i>=0; i--) {
        for (j=0; j<xsize; ++j) 
		{
		fprintf(fz, "%x\n",box[i*xsize+j]);
    }}
    
    free(image);
    fclose(fp);
    return 0;
}

#include "loadbmp.h"

unsigned char _default_lbheader[54] = {
    0x42,
    0x4d,
    0, 0, 0, 0,
    0, 0,
    0, 0,
    54, 0, 0, 0,
    40, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    1, 0,
    24, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0,
    0, 0, 0, 0 };

int readbmp(const char *filename, unsigned int *width, unsigned int *height, unsigned char **data) {
    unsigned int i;
    FILE* f = fopen(filename, "rb");
    unsigned char info[54];
    unsigned char colored=1;
    unsigned char *row_buffer=NULL;
    fread(info, sizeof(unsigned char), 54, f); // read the 54-byte header
    if (info[28]==8) // grascale
        colored=0;

    // extract image height and width from header
    *width  = *(int*)(info+18);
    *height = *(int*)(info+22);

    unsigned int row_size = (colored?3:1) * (*width);
    unsigned int row_size_padded = row_size + row_size%4 ; /* 4-byte alignment */
    unsigned int size = row_size * (*height);
    row_buffer = (unsigned char*)malloc(sizeof(unsigned char)*row_size_padded);
    *data = (unsigned char*)malloc(sizeof(unsigned char)*size); // allocate 3 bytes per pixel

    fseek(f, *(unsigned short*)(info+10), SEEK_SET);
    for (i=0; i<(*height); ++i) {
        fread(row_buffer, sizeof(unsigned char), row_size_padded, f);
        memcpy(*data+i*row_size, row_buffer, sizeof(unsigned char)*row_size);
    }
    free(row_buffer); row_buffer=NULL;
    fclose(f);

    if (colored) {
        for(i = 0; i < size; i += 3) {
            unsigned char tmp = (*data)[i];
            (*data)[i] = (*data)[i+2];
            (*data)[i+2] = tmp;
        }
    }

    return colored;
}

int writebmp(const char *filename, unsigned int width, unsigned int height, unsigned char *buffer) { 
    // only support raw 24bit RGB image (unsigned char array)
    // the output is 24bit BGR bitmap image
    unsigned char header[54];
    unsigned int image_size = width*height*3;
    unsigned int file_size = image_size + 54;
    unsigned int row_size     = width*3;
    unsigned int row_padding  = (row_size%4);
    unsigned int row_size_pad = row_size + row_padding;
    unsigned char *row_buffer = NULL;
    unsigned int i=0;
    FILE *fp_t = NULL;

    for (i=0; i<image_size; i+=3) {
        unsigned char tmp = buffer[i];
        buffer[i] = buffer[i+2];
        buffer[i+2] = tmp;
    }

    fp_t = fopen(filename, "wb");
    if (fp_t==NULL) return -1;

    memcpy(header, _default_lbheader, 54);
    header[2] = (unsigned char)(file_size & 0x000000ff);
    header[3] = (file_size >> 8)  & 0x000000ff;
    header[4] = (file_size >> 16) & 0x000000ff;
    header[5] = (file_size >> 24) & 0x000000ff;
    header[18] = width & 0x000000ff;
    header[19] = (width >> 8)  & 0x000000ff;
    header[20] = (width >> 16) & 0x000000ff;
    header[21] = (width >> 24) & 0x000000ff;
    header[22] = height &0x000000ff;
    header[23] = (height >> 8)  & 0x000000ff;
    header[24] = (height >> 16) & 0x000000ff;
    header[25] = (height >> 24) & 0x000000ff;

    fwrite(header, sizeof(unsigned char), 54, fp_t);

    row_buffer = (unsigned char*)malloc(sizeof(unsigned char)*row_size_pad);
    memset(row_buffer, 0x00, sizeof(unsigned char)*row_size_pad);

    for (i=0; i<height; ++i) {
        memcpy(row_buffer, buffer+row_size*i, sizeof(unsigned char)*row_size);
        fwrite(row_buffer, sizeof(unsigned char), row_size_pad, fp_t);
    }

    free(row_buffer); row_buffer=NULL;
    return file_size;
}

