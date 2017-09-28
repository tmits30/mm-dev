//------------------------------------------------------------------------------
// Simlation for MM6532 RIOT
//------------------------------------------------------------------------------

#include <fstream>
#include <iomanip>
#include <iostream>
#include <map>
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

    void Reset(
        const std::vector<std::tuple<addr_t, data_t>>& ram_vec,
        const uint8_t cs,
        const bool rs_n,
        const bool r_w,
        const addr_t a,
        const data_t d_in,
        const data_t pa_in,
        const data_t pb_in,
        const data_t dra,
        const data_t ddra,
        const data_t drb,
        const data_t ddrb)
    {
        // Reset
        RES_N(0); CLK(0);
        const auto end_clk = (PERIOD * 2) * 1;
        for (auto i = decltype(end_clk)(0); i < end_clk; ++i) {
            if ((i % PERIOD) == 0) {
                CLK(!CLK());
            }
            top_->eval();
        }

        // Set RAM
        auto *ram_ptr = MM6532_RAM(top_, mem);
        for (const auto& d : ram_vec) {
            ram_ptr[std::get<0>(d)] = std::get<1>(d);
        }

        // Set register
        RES_N(1); CLK(1);
        CS(cs); RS_N(rs_n); R_W(r_w);
        A(a); D_IN(d_in); PA_IN(pa_in); PB_IN(pb_in);
        DRA(dra); DDRA(ddra); DRB(drb); DDRB(ddrb);
    }

    struct Input
    {
        uint8_t cs;
        bool rs_n;
        bool r_w;
        addr_t a;
        data_t d_in;
        data_t pa_in;
        data_t pb_in;

        Input(const uint8_t cs, const bool rs_n, const bool r_w, const addr_t a,
              const data_t d_in, const data_t pa_in, const data_t pb_in) :
            cs(cs),
            rs_n(rs_n),
            r_w(r_w),
            a(a),
            d_in(d_in),
            pa_in(pa_in),
            pb_in(pb_in)
        {}
    };

    void Run(const int cycles, const std::map<int, Input>& inputs)
    {
        auto clock = 0;
        const auto end_clock = PERIOD * (2 * (cycles + 1) + 1) + time_;
        for (; time_ < end_clock; ++time_) {
            // Dump signals
            if (vcd_file_) {
                vcd_->dump(time_);
            }

            // Execute
            if ((time_ % PERIOD) == 0) {
                CLK(!CLK());
                clock += CLK();
                if (verbose_) {
                    ShowRegister();
                    ShowRam();
                }
            }
            top_->eval();

            const auto it = inputs.find(clock);
            if (it != inputs.end()) {
                const auto input = it->second;
                CS(input.cs);
                RS_N(input.rs_n);
                R_W(input.r_w);
                A(input.a);
                D_IN(input.d_in);
                PA_IN(input.pa_in);
                PB_IN(input.pb_in);
            }
            top_->eval();
        }
    }

    void SetRam(
        data_t *ram, const std::vector<std::tuple<addr_t, data_t>>& ram_vec)
    {
        constexpr auto DEPTH = 128;
        std::fill(ram, ram + DEPTH, 0);
        for (const auto& d : ram_vec) {
            ram[std::get<0>(d)] = std::get<1>(d);
        }
    }

    bool Verify(
        const std::vector<std::tuple<addr_t, data_t>>& ram_vec,
        const bool irq_n,
        const data_t d_out,
        const data_t pa_out,
        const data_t pb_out,
        const data_t dra,
        const data_t ddra,
        const data_t drb,
        const data_t ddrb)
    {
        bool ret = true;

        auto error_log = [](const int e, const int a, const int d = 2) {
            std::stringstream ret;
            ret << " (expected " << HexString(e, d)
                << ", actual " << HexString(a, d) << ")";
            return ret.str();
        };

        // Verify register
        auto verify_reg = [&ret, &error_log](
            const int e, const int a, const std::string name) {
            if (e != a) {
                ret = false;
                std::cout << "error: " << name << error_log(e, a) << std::endl;
            }
        };
        verify_reg(irq_n, IRQ_N(), "IRQ_N");
        verify_reg(d_out, D_OUT(), "Data");
        verify_reg(pa_out, PA_OUT(), "Port A");
        verify_reg(pb_out, PB_OUT(), "Port B");
        verify_reg(dra, DRA(), "DRA");
        verify_reg(ddra, DDRA(), "DDRA");
        verify_reg(drb, DRB(), "DRB");
        verify_reg(ddrb, DDRB(), "DDRB");

        // Verify memory
        constexpr auto RAM_DEPTH = 128;
        const auto *actual_ram = MM6532_RAM(top_, mem);
        auto expected_ram = std::make_unique<data_t[]>(RAM_DEPTH);
        SetRam(expected_ram.get(), ram_vec);
        for (auto i = decltype(RAM_DEPTH)(0); i < RAM_DEPTH; ++i) {
            const auto actual = actual_ram[i];
            const auto expected = expected_ram[i];
            if (actual != expected) {
                ret = false;
                std::cout << "error: RAM[" << HexString(i, 2) << "]"
                          << error_log(expected, actual)
                          << std::endl;
            }
        }

        return ret;
    }

    void ShowRegister() const
    {
        std::cout << "CLK=" << CLK() << " "
                  << "CS=" << CS() << " "
                  << "RS_N=" << RS_N() << " "
                  << "R_W=" << R_W() << " "
                  << "A=" << HexString(A(), 2) << " "
                  << "D_IN=" << HexString(D_IN(), 2) << " "
                  << "D_OUT=" << HexString(D_OUT(), 2) << " "
                  << "DRA=" << HexString(DRA(), 2) << " "
                  << "DDRA=" << HexString(DDRA(), 2) << " "
                  << "DRB=" << HexString(DRB(), 2) << " "
                  << "DDRB=" << HexString(DDRB(), 2) << " "
                  << std::endl;
    }

    void ShowRam() const
    {
        auto *ram_ptr = MM6532_RAM(top_, mem);
        for (auto i = 0; i < 128; ++i) {
            const auto data = ram_ptr[i];
            if (data != 0x00) {
                std::cout << HexString(i, 4) << "<=" << HexString(data);
            }
        }
        std::cout << std::endl;
    }

    // Getter
    bool CLK() { return top_->CLK; }
    bool RES_N() { return top_->RES_N; }
    bool R_W() { return top_->R_W; }
    uint8_t CS() { return top_->CS; }
    bool RS_N() { return top_->RS_N; }
    addr_t A() { return top_->A; }
    data_t D_IN() { return top_->D_IN; }
    data_t PA_IN() { return top_->PA_IN; }
    data_t PB_IN() { return top_->PB_IN; }
    bool IRQ_N() { return top_->IRQ_N; }
    data_t D_OUT() { return top_->D_OUT; }
    data_t PA_OUT() { return top_->PA_OUT; }
    data_t PB_OUT() { return top_->PB_OUT; }
    data_t DRA() { return MM6532_TOP(top_, dra); }
    data_t DDRA() { return MM6532_TOP(top_, ddra); }
    data_t DRB() { return MM6532_TOP(top_, drb); }
    data_t DDRB() { return MM6532_TOP(top_, ddrb); }

    const bool CLK() const { return top_->CLK; }
    const bool RES_N() const { return top_->RES_N; }
    const bool R_W() const { return top_->R_W; }
    const uint8_t CS() const { return top_->CS; }
    const bool RS_N() const { return top_->RS_N; }
    const addr_t A() const { return top_->A; }
    const data_t D_IN() const { return top_->D_IN; }
    const data_t PA_IN() const { return top_->PA_IN; }
    const data_t PB_IN() const { return top_->PB_IN; }
    const bool IRQ_N() const { return top_->IRQ_N; }
    const data_t D_OUT() const { return top_->D_OUT; }
    const data_t PA_OUT() const { return top_->PA_OUT; }
    const data_t PB_OUT() const { return top_->PB_OUT; }
    const data_t DRA() const { return MM6532_TOP(top_, dra); }
    const data_t DDRA() const { return MM6532_TOP(top_, ddra); }
    const data_t DRB() const { return MM6532_TOP(top_, drb); }
    const data_t DDRB() const { return MM6532_TOP(top_, ddrb); }

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
    void DRA(const data_t wd) { MM6532_TOP(top_, dra) = wd; }
    void DDRA(const data_t wd) { MM6532_TOP(top_, ddra) = wd; }
    void DRB(const data_t wd) { MM6532_TOP(top_, drb) = wd; }
    void DDRB(const data_t wd) { MM6532_TOP(top_, ddrb) = wd; }

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

    // Load memory vector from yaml file function
    auto load_ram = [](const YAML::Node& ram_node) {
        std::vector<std::tuple<TestBench::addr_t, TestBench::data_t>> ret;
        for (const auto& ram : ram_node) {
            const auto addr = ram.first.as<int>();
            const auto data = ram.second.as<int>();
            ret.emplace_back(
                std::tuple<TestBench::addr_t, TestBench::data_t>(addr, data));
        }
        return ret;
    };

    // Run tests from yaml file
    for (const auto& target : test_patterns) {
        const auto target_name = target["target"].as<std::string>();

        for (const auto& test : target["tests"]) {
            const auto comment = test["comment"].as<std::string>();

            // Execute a test pattern
            const auto& initial = test["initial"];
            tb->Reset(
                load_ram(initial["ram"]),
                initial["reg"]["CS"].as<int>(),
                initial["reg"]["RS_N"].as<int>(),
                initial["reg"]["R_W"].as<int>(),
                initial["reg"]["A"].as<int>(),
                initial["reg"]["D_IN"].as<int>(),
                initial["reg"]["PA_IN"].as<int>(),
                initial["reg"]["PB_IN"].as<int>(),
                initial["reg"]["DRA"].as<int>(),
                initial["reg"]["DDRA"].as<int>(),
                initial["reg"]["DRB"].as<int>(),
                initial["reg"]["DDRB"].as<int>()
            );

            // Run
            std::map<int, TestBench::Input> inputs;
            for (const auto& command : test["command"]) {
                inputs.emplace(
                    command["clock"].as<int>(),
                    TestBench::Input(
                        command["reg"]["CS"].as<int>(),
                        command["reg"]["RS_N"].as<int>(),
                        command["reg"]["R_W"].as<int>(),
                        command["reg"]["A"].as<int>(),
                        command["reg"]["D_IN"].as<int>(),
                        command["reg"]["PA_IN"].as<int>(),
                        command["reg"]["PB_IN"].as<int>()
                    )
                );
            }
            tb->Run(test["cycle"].as<int>(), inputs);

            // Verify the test
            const auto& expected = test["expected"];
            const auto is_valid = tb->Verify(
                load_ram(expected["ram"]),
                expected["reg"]["IRQ_N"].as<int>(),
                expected["reg"]["D_OUT"].as<int>(),
                expected["reg"]["PA_OUT"].as<int>(),
                expected["reg"]["PB_OUT"].as<int>(),
                expected["reg"]["DRA"].as<int>(),
                expected["reg"]["DDRA"].as<int>(),
                expected["reg"]["DRB"].as<int>(),
                expected["reg"]["DDRB"].as<int>()
            );

            std::cout << (is_valid ? "Success" : "   Fail") << ": "
                      << target_name << ": "
                      << comment << std::endl;
        }
    }

    return 0;
}
