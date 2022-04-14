#!/usr/bin/env python3
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge
from cocotb.regression import TestFactory
from cocotb.result import TestFailure, TestSuccess


class display_controller(object):
    def __init__(self, dut):
        self.dut = dut
        self.clk = dut.clk
        self.height = dut.DISP_HEIGHT
        self.width = dut.DISP_WIDTH

    @cocotb.coroutine
    async def startup(self):
        self.dut.wr_en.setimmediatevalue(0)
        self.dut.wr_x.setimmediatevalue(0)
        self.dut.wr_y.setimmediatevalue(0)
        self.dut.wr_c.setimmediatevalue(0)

        self.dut.rd_en.setimmediatevalue(0)
        self.dut.rd_x.setimmediatevalue(0)
        self.dut.rd_y.setimmediatevalue(0)

        self.dut.display_flip.setimmediatevalue(0)
        cocotb.fork(Clock(self.clk, 4, units="ns").start())
        await RisingEdge(self.clk)

    @cocotb.coroutine
    async def write_pixel(self, x, y, c):
        await RisingEdge(self.clk)
        self.dut.wr_en.value = 1
        self.dut.wr_x.value = x
        self.dut.wr_y.value = y
        self.dut.wr_c.value = c
        await RisingEdge(self.clk)
        self.dut.wr_en.value = 0

    @cocotb.coroutine
    async def read_pixel(self, x, y):
        self.dut.rd_x.value = x
        self.dut.rd_y.value = y
        await RisingEdge(self.clk)
        await RisingEdge(self.clk)
        # print("Time is %d" % cocotb.utils.get_sim_time())
        c = self.dut.rd_c.value
        print("rc has value %d" % int(c))
        return int(c)

    @cocotb.coroutine
    async def flip_display(self):
        await RisingEdge(self.clk)
        self.dut.display_flip.value = 1
        await RisingEdge(self.clk)
        self.dut.display_flip.value = 0

    def print_memory(self, bank_index):
        assert bank_index in [0, 1]


@cocotb.test()
async def first_test(dut, color_index=0):
    dc = display_controller(dut)
    await dc.startup()

    pixel_X = 5
    pixel_Y = 5
    ci = color_index
    await dc.write_pixel(pixel_X, pixel_Y, color_index)
    await dc.flip_display()
    pixel_color = await dc.read_pixel(pixel_X, pixel_Y)
    print(pixel_color)
    print(type(pixel_color))
    if pixel_color == ci:
        raise TestSuccess()
    else:
        raise TestFailure("pixel color isn't 4")
    await RisingEdge(dut.clk)
    print("Pixel color is: %s" % str(pixel_color))


tf = TestFactory(test_function=first_test)
tf.add_option(name="color_index", optionlist=list(range(0, 16)))
tf.generate_tests()
