//------------------------------------------------------------------------------
// Simlation for MM6532 RIOT
//------------------------------------------------------------------------------

#include <fstream>
#include <iomanip>
#include <iostream>
#include <memory>

#include <yaml-cpp/yaml.h>

#include "verilated_vcd_c.h"
#include "Vmm6532.h"


template <typename T>
decltype(auto) HexString(const T& x, const int d = 2)
{
    std::stringstream ret;
    ret << "0x" << std::hex << std::setw(d) << std::setfill('0')
        << static_cast<int>(x);
    return ret.str();
}


class TestBench
{
#define MM6532_TOP(ptr, element) \
    (ptr)->mm6532__DOT__##element
#define MM6532_ITIMER(ptr, element) \
    (ptr)->mm6532__DOT__itimer__DOT__##element
#define MM6532_RAM(ptr, element) \
    (ptr)->mm6532__DOT__ram__DOT__##element

public:

    using addr_t = vluint8_t; // 7bit
    using data_t = vluint8_t; // 8bit

    const int PERIOD = 1;

    TestBench(const char *vcd_file = nullptr, const bool verbose = false) :
        top_(std::make_unique<Vmm6532>("top")),
        vcd_(std::make_unique<VerilatedVcdC>()),
        vcd_file_(vcd_file),
        verbose_(verbose),
        time_(0)
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

    void Reset()
    {
    }

    void Run(const int cycles)
    {
    }

    bool Verify()
    {
        bool ret = true;

        return ret;
    }

    void ShowRegister() const
    {
    }

    void ShowRam() const
    {
    }

    // Getter
    auto CLK() { return top_->CLK; }
    auto RES_N() { return top_->RES_N; }
    auto R_W() { return top_->R_W; }
    auto CS() { return top_->CS; }
    auto RS_N() { return top_->RS_N; }
    auto A() { return top_->A; }
    auto D_IN() { return top_->D_IN; }
    auto PA_IN() { return top_->PA_IN; }
    auto PB_IN() { return top_->PB_IN; }
    auto IRQ_N() { return top_->IRQ_N; }
    auto D_OUT() { return top_->D_OUT; }
    auto PA_OUT() { return top_->PA_OUT; }
    auto PB_OUT() { return top_->PB_OUT; }

    const auto CLK() const { return top_->CLK; }
    const auto RES_N() const { return top_->RES_N; }
    const auto R_W() const { return top_->R_W; }
    const auto CS() const { return top_->CS; }
    const auto RS_N() const { return top_->RS_N; }
    const auto A() const { return top_->A; }
    const auto D_IN() const { return top_->D_IN; }
    const auto PA_IN() const { return top_->PA_IN; }
    const auto PB_IN() const { return top_->PB_IN; }
    const auto IRQ_N() const { return top_->IRQ_N; }
    const auto D_OUT() const { return top_->D_OUT; }
    const auto PA_OUT() const { return top_->PA_OUT; }
    const auto PB_OUT() const { return top_->PB_OUT; }

    // Setter
    void CLK(const bool wd) { top_->CLK = wd; }
    void RES_N(const bool wd) { top_->RES_N = wd; }
    void R_W(const bool wd) { top_->R_W = wd; }
    void CS(const uint8_t wd) { top_->CS = wd; }
    void RS_N(const bool wd) { top_->RS_N = wd; }
    void A(const addr_t wd) { top_->A = wd; }
    void D_IN(const data_t wd) { top_->D_IN = wd; }
    void PA_IN(const data_t wd) { top_->PA_IN = wd; }
    void PB_IN(const data_t wd) { top_->PB_IN = wd; }

private:

    std::unique_ptr<Vmm6532> top_;
    std::unique_ptr<VerilatedVcdC> vcd_;
    const char *vcd_file_;
    const bool verbose_;

    int time_;

#undef MM6532_TOP
#undef MM6532_ITIMER
#undef MM6532_RAM
};


int main(int argc, char **argv)
{
    // Intialize Verilated
    Verilated::commandArgs(argc, argv);

    // Create testbench
    auto tb = std::make_unique<TestBench>("sim_mm6532.vcd");

    // Read test config yaml file
    const auto test_patterns = YAML::LoadFile("sim_mm6532.yml");

    return 0;
}
