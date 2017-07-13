//------------------------------------------------------------------------------
// Simlation for MC6502 MPU
//------------------------------------------------------------------------------

#include <iomanip>
#include <iostream>
#include <memory>
#include <stdio.h>

#include "verilated_vcd_c.h"
#include "Vmpu.h"


template <typename T, int D = 2>
decltype(auto) HexString(const T& x)
{
    std::stringstream ret;
    ret << std::hex << std::setw(D) << std::setfill('0') << static_cast<int>(x);
    return ret.str();
}


class Memory
{
public:

    using bus_t = vluint8_t;
    using addr_t = vluint16_t;

    Memory(const std::size_t bits = 8, const std::size_t depth = 0xffff) :
        bits_(bits),
        depth_(depth),
        buf_(std::make_unique<bus_t[]>(depth))
    {
        Reset();
    }

    const bus_t Read(const addr_t ra) const
    {
        return buf_[ra];
    }

    void Write(const addr_t wa, const bus_t wd, const bool we)
    {
        if (we) buf_[wa] = wd;
    }

    void Write(const std::tuple<addr_t, bus_t> data)
    {
        Write(std::get<0>(data), std::get<1>(data), true);
    }

    void Reset()
    {
        std::fill(buf_.get(), buf_.get() + depth_, 0);
    }

    void Show()
    {
        for (auto i = decltype(depth_)(0); i < depth_; ++i) {
            if (buf_[i] != 0x00) {
                printf("0x%04lx<=0x%02x ", i, buf_[i]);
            }
        }
        printf("\n");
    }


private:

    const std::size_t bits_;
    const std::size_t depth_;
    std::unique_ptr<bus_t[]> buf_;
};


class TestBench
{
public:

    using bus_t = vluint8_t;
    using addr_t = vluint16_t;
    using mem_t = std::tuple<addr_t, bus_t>;

    const int PERIOD = 1;

    TestBench(const char *vcd_file = nullptr, const bool verbose = true) :
        top_(std::make_unique<Vmpu>("top")),
        mem_(std::make_unique<Memory>()),
        vcd_(std::make_unique<VerilatedVcdC>()),
        vcd_file_(vcd_file),
        verbose_(verbose)
    {
        if (vcd_file_) {
            Verilated::traceEverOn(true);
            top_->trace(vcd_.get(), 99);
            vcd_->open(vcd_file_);
        }
    }

    ~TestBench()
    {
        if (vcd_file_) {
            vcd_->close();
        }
        top_->final();
    }

    void Reset(
        const std::vector<mem_t>& mem,
        const addr_t a = 0x00,
        const addr_t x = 0x00,
        const addr_t y = 0x00,
        const addr_t s = 0xff,
        const addr_t p = 0x00,
        const addr_t ab = 0x00,
        const addr_t pc = 0x00)
    {
        // Reset memory
        for (auto d : mem) mem_->Write(d);

        // Reset register
        RDY(1); RES_N(0); CLK(0);
        const auto end_clk = (PERIOD * 2) * 1;
        for (auto i = decltype(end_clk)(0); i < end_clk; ++i) {
            if ((i % PERIOD) == 0) {
                CLK(!CLK());
            }
            top_->eval();
        }

        // Set register
        RES_N(1); CLK(1);
        A(a); X(x); Y(y); S(s); P(p); AB(ab); PC(pc);
    }

    void Run(const int cycles)
    {
        const auto end_clk = (PERIOD * 2) * (cycles + 1);
        for (auto i = decltype(end_clk)(0); i < end_clk; ++i) {
            // Memory ops
            DB_IN(mem_->Read(AB()));
            mem_->Write(AB(), DB_OUT(), R_W() == 0);

            // Dump signals
            if (vcd_file_) {
                vcd_->dump(i);
            }

            // Execute
            if ((i % PERIOD) == 0) {
                CLK(!CLK());
                if (verbose_) {
                    ShowRegister();
                    ShowMemory();
                }
            }
            top_->eval();
        }
    }

    void ShowRegister() const
    {
        printf("CLK=%d PC=0x%04x AB=0x%04x DBI=0x%02x DBO=0x%02x "
               "A=0x%02x X=0x%02x Y=0x%02x S=0x%02x P=0x%02x\n",
               CLK(), PC(), AB(), DB_IN(), DB_OUT(), A(), X(), Y(), S(), P());
    }

    void ShowMemory() const
    {
        mem_->Show();
    }

    // Getter
    bool CLK() { return top_->CLK; }
    bool RES_N() { return top_->RES_N; }
    bool RDY() { return top_->RDY; }
    bool R_W() { return top_->R_W; }

    bus_t ABL() { return top_->ABL; }
    bus_t ABH() { return top_->ABH; }
    addr_t AB() { return (ABH() << 8) + ABL(); }
    bus_t DB_IN() { return top_->DB_IN; }
    bus_t DB_OUT() { return top_->DB_OUT; }

    bus_t A() { return top_->mpu__DOT__datapath__DOT__a; }
    bus_t X() { return top_->mpu__DOT__datapath__DOT__x; }
    bus_t Y() { return top_->mpu__DOT__datapath__DOT__y; }
    bus_t S() { return top_->mpu__DOT__datapath__DOT__s; }
    bus_t T() { return top_->mpu__DOT__datapath__DOT__t; }
    bus_t P() { return top_->mpu__DOT__datapath__DOT__p; }
    bus_t PCL() { return top_->mpu__DOT__datapath__DOT__pcl; }
    bus_t PCH() { return top_->mpu__DOT__datapath__DOT__pch; }
    addr_t PC() { return (PCH() << 8) + PCL(); }
    bus_t IR() { return top_->mpu__DOT__instr; }

    const bool CLK() const { return top_->CLK; }
    const bool RES_N() const { return top_->RES_N; }
    const bool RDY() const { return top_->RDY; }
    const bool R_W() const { return top_->R_W; }

    const bus_t ABL() const { return top_->ABL; }
    const bus_t ABH() const { return top_->ABH; }
    const addr_t AB() const { return (ABH() << 8) + ABL(); }
    const bus_t DB_IN() const { return top_->DB_IN; }
    const bus_t DB_OUT() const { return top_->DB_OUT; }

    const bus_t A() const { return top_->mpu__DOT__datapath__DOT__a; }
    const bus_t X() const { return top_->mpu__DOT__datapath__DOT__x; }
    const bus_t Y() const { return top_->mpu__DOT__datapath__DOT__y; }
    const bus_t S() const { return top_->mpu__DOT__datapath__DOT__s; }
    const bus_t T() const { return top_->mpu__DOT__datapath__DOT__t; }
    const bus_t P() const { return top_->mpu__DOT__datapath__DOT__p; }
    const bus_t PCL() const { return top_->mpu__DOT__datapath__DOT__pcl; }
    const bus_t PCH() const { return top_->mpu__DOT__datapath__DOT__pch; }
    const addr_t PC() const { return (PCH() << 8) + PCL(); }
    const bus_t IR() const { return top_->mpu__DOT__instr; }

    // Setter
    void CLK(const bool wd) { top_->CLK = wd; }
    void RES_N(const bool wd) { top_->RES_N = wd; }
    void RDY(const bool wd) { top_->RDY = wd; }

    void ABL(const bus_t wd) { top_->ABL = wd; }
    void ABH(const bus_t wd) { top_->ABH = wd; }
    void AB(const addr_t wd) { ABL(wd & 0xff); ABH((wd >> 8) & 0xff); }
    void DB_IN(const bus_t wd) { top_->DB_IN = wd; }
    void DB_OUT(const bus_t wd) { top_->DB_OUT = wd; }

    void A(const bus_t wd) { top_->mpu__DOT__datapath__DOT__a = wd; }
    void X(const bus_t wd) { top_->mpu__DOT__datapath__DOT__x = wd; }
    void Y(const bus_t wd) { top_->mpu__DOT__datapath__DOT__y = wd; }
    void S(const bus_t wd) { top_->mpu__DOT__datapath__DOT__s = wd; }
    void T(const bus_t wd) { top_->mpu__DOT__datapath__DOT__t = wd; }
    void P(const bus_t wd) { top_->mpu__DOT__datapath__DOT__p = wd; }
    void PCL(const bus_t wd) { top_->mpu__DOT__datapath__DOT__pcl = wd; }
    void PCH(const bus_t wd) { top_->mpu__DOT__datapath__DOT__pch = wd; }
    void PC(const addr_t wd) { PCL(wd & 0xff); PCH((wd >> 8) & 0xff); }
    void IR(const bus_t wd) { top_->mpu__DOT__instr = wd; }

    // Memory Operations
    const bus_t RData(const addr_t ra) const
    {
        return mem_->Read(ra);
    }

    void WData(const addr_t wa, const bus_t wd, const bool we)
    {
        return mem_->Write(wa, wd, we);
    }


private:

    std::unique_ptr<Vmpu> top_;
    std::unique_ptr<Memory> mem_;
    std::unique_ptr<VerilatedVcdC> vcd_;
    const char *vcd_file_;
    const bool verbose_;
};


int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv);

    auto tb = std::make_unique<TestBench>("sim_mpu.vcd");

    TestBench::mem_t mem[] = {
        TestBench::mem_t(0x0000, 0x38),
    };
    tb->Reset(std::vector<TestBench::mem_t>(mem, mem + 1),
              0x11, 0x22, 0x33, 0xef, 0x20);
    tb->Run(2);

    return 0;
}
