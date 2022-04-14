#include <stdio.h>
#include <SDL.h>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "Vtop_square.h"
#include <cstdint>
#include <fstream>
#include <iostream>
#include <string>

using namespace std;

// https://dev.to/muiz6/c-how-to-write-a-bitmap-image-from-scratch-1k6m

struct __attribute__ ((packed)) BmpHeader {
  char bitmapSignatureBytes[2] = {'B', 'M'};
  uint32_t sizeOfBitmapFile = 54 + (640*480*3);
  uint32_t reservedBytes = 0;
  uint32_t pixelDataOffset = 54;
} bmpHeader;

struct BmpInfoHeader {
  uint32_t sizeOfThisHeader = 40;
  int32_t width = 640;
  int32_t height = 480;
  uint16_t numberOfColorPlanes = 1;
  uint16_t colorDepth = 24;
  uint32_t compressionMethod = 0;
  uint32_t rawBitmapDataSize = 0;
  int32_t horizontalResolution = 3780;
  int32_t verticalResolution = 3780;
  uint32_t colorTableEntries = 0;
  uint32_t importantColors = 0;
} bmpInfoHeader;

typedef struct BmpPixel {
  uint8_t blue;
  uint8_t green;
  uint8_t red;
} bmpPixel;

// screen dimensions
const int H_RES = 640;
const int V_RES = 480;

typedef struct Pixel {
  uint8_t a;
  uint8_t b;
  uint8_t g;
  uint8_t r;
} Pixel;

typedef struct Image {
  bmpPixel pixels[V_RES][H_RES];
} image;

int writeBmp (string fn, Image *img) {
  std::cout << "Calling writeBmp\n";

  if (img == 0) {
    std::cerr << ("writebmp with null pointer");
  } else {
    ofstream fout(fn, ios::binary);
    std::cout << "writing headers\n";
    fout.write((char *) &bmpHeader, 14);
    fout.write((char *) &bmpInfoHeader, 40);

    std::cout << "writing pixels\n";
    for (int i = 0; i < V_RES; i++) {
      for (int j = 0; j < H_RES; j++) {
        bmpPixel p = img->pixels[i][j];
        fout.put(p.blue & 0x0ff);
        fout.put(p.green & 0x0ff);
        fout.put(p.red & 0x0ff);
      }
    }
    fout.close();
  }
  return 0;
}

double sc_time_stamp() { return 0; }
vluint64_t main_time = 0;

#define SINGLE_FRAME_TIME 307200
#define MAX_SIM_TIME SINGLE_FRAME_TIME*10

int main (int argc, char * argv[]) {
  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC *m_trace = new VerilatedVcdC;

  if (SDL_Init(SDL_INIT_VIDEO) < 0) {
    printf("SDL init failed.\n");
    return 1;
  }

  Pixel screenbuffer[H_RES*V_RES];

  SDL_Window*   sdl_window   = NULL;
  SDL_Renderer* sdl_renderer = NULL;
  SDL_Texture*  sdl_texture  = NULL;

  sdl_window = SDL_CreateWindow("Top Square",
                                SDL_WINDOWPOS_CENTERED,
                                SDL_WINDOWPOS_CENTERED,
                                H_RES,
                                V_RES,
                                SDL_WINDOW_SHOWN);

  if (!sdl_window) {
    printf("Window creation failed: %s\n", SDL_GetError());
    return 1;
  }

  sdl_renderer = SDL_CreateRenderer(sdl_window, -1,
                                    SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);

  if (!sdl_renderer) {
    printf("Renderer creation failed: %s\n", SDL_GetError());
    return 1;
  }

  sdl_texture = SDL_CreateTexture(sdl_renderer,
                                  SDL_PIXELFORMAT_RGBA8888,
                                  SDL_TEXTUREACCESS_TARGET,
                                  H_RES,
                                  V_RES);

  if (!sdl_texture) {
    printf("Texture creation failed: %s\n", SDL_GetError());
    return 1;
  }

  Vtop_square * top = new Vtop_square;
  top->trace(m_trace, 1);
  m_trace->open("waveform.vcd");

  top->rst = 1;
  top->clk_pix = 0;
  top->eval();
  top->rst = 0;
  top->eval();



  uint64_t frame_count = 0;
  uint64_t start_ticks = SDL_GetPerformanceCounter();
  image  myImage;
  int imageCount = 0;
  string imageName = "frame";
  while (main_time < MAX_SIM_TIME) {
    main_time++;
    top->clk_pix = 1;
    top->eval();
    top->clk_pix = 0;
    top->eval();

    if (main_time > 0 && main_time % SINGLE_FRAME_TIME == 0) {
      std::cout << "Time to write frame\n";
      string currImageName = imageName.append(std::to_string(imageCount));
      currImageName = currImageName.append(".bmp");

      writeBmp (currImageName, &myImage);
      imageName = "frame";
      imageCount++;
    }

    if (top->de) {
      Pixel * p = &screenbuffer[top->sy*H_RES + top->sx];
      p->a = 0xFF;
      p->b = top->sdl_b;
      p->g = top->sdl_g;
      p->r = top->sdl_r;

      myImage.pixels[top->sy][top->sx].blue = top->sdl_b;
      myImage.pixels[top->sy][top->sx].red = top->sdl_r;
      myImage.pixels[top->sy][top->sx].green = top->sdl_g;
    }

    if (top->sy == V_RES && top->sx == 0) {
      SDL_Event e;
      if (SDL_PollEvent(&e)) {
        if (e.type == SDL_QUIT) {
          break;
        }
      }

      SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES*sizeof(Pixel));
      SDL_RenderClear(sdl_renderer);
      SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
      SDL_RenderPresent(sdl_renderer);
      frame_count++;
    }

    m_trace->dump(main_time);
  }
  uint64_t end_ticks = SDL_GetPerformanceCounter();
  double duration = ((double)(end_ticks-start_ticks))/SDL_GetPerformanceFrequency();
  double fps = (double)frame_count/duration;
  printf("Frames per second: %.1f\n", fps);

  top->final();
  m_trace->close();
  SDL_DestroyTexture(sdl_texture);
  SDL_DestroyRenderer(sdl_renderer);
  SDL_DestroyWindow(sdl_window);
  SDL_Quit();
  return 0;
}
