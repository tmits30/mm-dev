//------------------------------------------------------------------------------
// Simlation for MC6502 MPU
//------------------------------------------------------------------------------

#include <fstream>
#include <iomanip>
#include <iostream>
#include <memory>

#include <yaml-cpp/yaml.h>

#include "verilated_vcd_c.h"
#include "Vmpu.h"


template <typename T>
decltype(auto) HexString(const T& x, const int d = 2)
{
    std::stringstream ret;
    ret << "0x" << std::hex << std::setw(d) << std::setfill('0')
        << static_cast<int>(x);
    return ret.str();
}


template <typename addr_t, typename data_t>
class Memory
{
public:

    Memory(const std::size_t bits = 8, const std::size_t depth = 0xffff) :
        bits_(bits),
        depth_(depth),
        buf_(std::make_unique<data_t[]>(depth))
    {
        Reset();
    }

    const data_t Read(const addr_t ra) const
    {
        return buf_[ra];
    }

    void Write(const addr_t wa, const data_t wd, const bool we)
    {
        if (we) buf_[wa] = wd;
    }

    void Write(const std::tuple<addr_t, data_t>& data)
    {
        Write(std::get<0>(data), std::get<1>(data), true);
    }

    void Reset()
    {
        std::fill(buf_.get(), buf_.get() + depth_, 0);
    }

    void Set(const std::vector<std::tuple<addr_t, data_t>>& mem_vec)
    {
        for (const auto& d : mem_vec) Write(d);
    }

    // Getter
    std::size_t Depth() { return depth_; }
    std::size_t Bits() { return bits_; }
    const std::size_t Depth() const { return depth_; }
    const std::size_t Bits() const { return bits_; }

private:

    const std::size_t bits_;
    const std::size_t depth_;
    std::unique_ptr<data_t[]> buf_;
};


class TestBench
{
#define MPU_TOP(ptr, element) \
    (ptr)->mpu__DOT__##element
#define MPU_CONTROLLER(ptr, element) \
    (ptr)->mpu__DOT__controller__DOT__##element
#define MPU_DATAPATH(ptr, element) \
    (ptr)->mpu__DOT__datapath__DOT__##element

public:

    using addr_t = vluint16_t;
    using data_t = vluint8_t;

    const int PERIOD = 1;

    TestBench(const char *vcd_file = nullptr, const bool verbose = false) :
        top_(std::make_unique<Vmpu>("top")),
        mem_(std::make_unique<Memory<addr_t, data_t>>()),
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
        const std::vector<std::tuple<addr_t, data_t>>& mem_vec,
        const data_t a,
        const data_t x,
        const data_t y,
        const data_t s,
        const data_t p,
        const addr_t ab,
        const addr_t pc)
    {
        // Reset memory
        mem_->Reset();
        mem_->Set(mem_vec);

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
        MPU_CONTROLLER(top_, cur_state) = 0;
        MPU_CONTROLLER(top_, nxt_state) = 1;
    }

    void Run(const int cycles)
    {
        const auto end_clk = PERIOD * (2 * (cycles + 1) + 1) + time_;
        for (; time_ < end_clk; ++time_) {
            // Memory ops
            DB_IN(mem_->Read(AB()));
            mem_->Write(AB(), DB_OUT(), R_W() == 0);

            // Dump signals
            if (vcd_file_) {
                vcd_->dump(time_);
            }

            // Execute
            if ((time_ % PERIOD) == 0) {
                CLK(!CLK());
                if (verbose_) {
                    ShowRegister();
                    ShowMemory();
                }
            }
            top_->eval();
        }
    }

    bool Verify(
        const std::vector<std::tuple<addr_t, data_t>>& mem_vec,
        const data_t a,
        const data_t x,
        const data_t y,
        const data_t s,
        const data_t p,
        const addr_t ab,
        const addr_t pc)
    {
        bool ret = true;

        auto error_log = [](const int e, const int a, const int d = 2) {
            std::stringstream ret;
            ret << " (expected " << HexString(e, d)
                << ", actual " << HexString(a, d) << ")";
            return ret.str();
        };

        // Verify register
        if (A() != a) {
            ret = false;
            std::cout << "error: A register"
                      << error_log(a, A()) << std::endl;
        }
        if (X() != x) {
            ret = false;
            std::cout << "error: X register"
                      << error_log(x, X()) << std::endl;
        }
        if (Y() != y) {
            ret = false;
            std::cout << "error: Y register"
                      << error_log(y, Y()) << std::endl;
        }
        if (S() != s) {
            ret = false;
            std::cout << "error: S register"
                      << error_log(s, S()) << std::endl;
        }
        if (P() != p) {
            ret = false;
            std::cout << "error: P register"
                      << error_log(p, P()) << std::endl;
        }
        if (AB() != ab) {
            ret = false;
            std::cout << "error: AB register"
                      << error_log(ab, AB(), 4) << std::endl;
        }
        if (PC() != pc) {
            ret = false;
            std::cout << "error: PC register"
                      << error_log(pc, PC(), 4) << std::endl;
        }

        // Verify memory
        const auto mem_depth = mem_->Depth();
        auto expected_mem = std::make_unique<Memory<addr_t, data_t>>();
        expected_mem->Set(mem_vec);
        for (auto i = decltype(mem_depth)(0); i < mem_depth; ++i) {
            if (mem_->Read(i) != expected_mem->Read(i)) {
                ret = false;
                std::cout << "error: address " << HexString(i, 4)
                          << error_log(expected_mem->Read(i), mem_->Read(i))
                          << std::endl;
            }
        }

        return ret;
    }

    void ShowRegister() const
    {
        std::cout << "CLK=" << CLK() << " "
                  << "PC=" << HexString(PC(), 4) << " "
                  << "AB=" << HexString(AB(), 4) << " "
                  << "DBI=" << HexString(DB_IN(), 2) << " "
                  << "DBO=" << HexString(DB_OUT(), 2) << " "
                  << "A=" << HexString(A(), 2) << " "
                  << "X=" << HexString(X(), 2) << " "
                  << "Y=" << HexString(Y(), 2) << " "
                  << "S=" << HexString(S(), 2) << " "
                  << "P=" << HexString(P(), 2) << std::endl;
    }

    void ShowMemory() const
    {
        for (auto i = decltype(mem_->Depth())(0); i < mem_->Depth(); ++i) {
            if (mem_->Read(i) != 0x00) {
                std::cout << HexString(i, 4) << "<=" << HexString(mem_->Read(i));
            }
        }
        std::cout << std::endl;
    }

    // Getter
    bool CLK() { return top_->CLK; }
    bool RES_N() { return top_->RES_N; }
    bool RDY() { return top_->RDY; }
    bool R_W() { return top_->R_W; }

    data_t ABL() { return top_->ABL; }
    data_t ABH() { return top_->ABH; }
    addr_t AB() { return (ABH() << 8) + ABL(); }
    data_t DB_IN() { return top_->DB_IN; }
    data_t DB_OUT() { return top_->DB_OUT; }

    data_t A() { return MPU_DATAPATH(top_, a); }
    data_t X() { return MPU_DATAPATH(top_, x); }
    data_t Y() { return MPU_DATAPATH(top_, y); }
    data_t S() { return MPU_DATAPATH(top_, s); }
    data_t T() { return MPU_DATAPATH(top_, t); }
    data_t P() { return MPU_DATAPATH(top_, p); }
    data_t PCL() { return MPU_DATAPATH(top_, pcl); }
    data_t PCH() { return MPU_DATAPATH(top_, pch); }
    addr_t PC() { return (PCH() << 8) + PCL(); }
    data_t IR() { return MPU_TOP(top_, instr); }

    const bool CLK() const { return top_->CLK; }
    const bool RES_N() const { return top_->RES_N; }
    const bool RDY() const { return top_->RDY; }
    const bool R_W() const { return top_->R_W; }

    const data_t ABL() const { return top_->ABL; }
    const data_t ABH() const { return top_->ABH; }
    const addr_t AB() const { return (ABH() << 8) + ABL(); }
    const data_t DB_IN() const { return top_->DB_IN; }
    const data_t DB_OUT() const { return top_->DB_OUT; }

    const data_t A() const { return MPU_DATAPATH(top_, a); }
    const data_t X() const { return MPU_DATAPATH(top_, x); }
    const data_t Y() const { return MPU_DATAPATH(top_, y); }
    const data_t S() const { return MPU_DATAPATH(top_, s); }
    const data_t T() const { return MPU_DATAPATH(top_, t); }
    const data_t P() const { return MPU_DATAPATH(top_, p); }
    const data_t PCL() const { return MPU_DATAPATH(top_, pcl); }
    const data_t PCH() const { return MPU_DATAPATH(top_, pch); }
    const addr_t PC() const { return (PCH() << 8) + PCL(); }
    const data_t IR() const { return MPU_TOP(top_, instr); }

    // Setter
    void CLK(const bool wd) { top_->CLK = wd; }
    void RES_N(const bool wd) { top_->RES_N = wd; }
    void RDY(const bool wd) { top_->RDY = wd; }

    void ABL(const data_t wd) { top_->ABL = wd; }
    void ABH(const data_t wd) { top_->ABH = wd; }
    void AB(const addr_t wd) { ABL(wd & 0xff); ABH((wd >> 8) & 0xff); }
    void DB_IN(const data_t wd) { top_->DB_IN = wd; }
    void DB_OUT(const data_t wd) { top_->DB_OUT = wd; }

    void A(const data_t wd) { MPU_DATAPATH(top_, a) = wd; }
    void X(const data_t wd) { MPU_DATAPATH(top_, x) = wd; }
    void Y(const data_t wd) { MPU_DATAPATH(top_, y) = wd; }
    void S(const data_t wd) { MPU_DATAPATH(top_, s) = wd; }
    void T(const data_t wd) { MPU_DATAPATH(top_, t) = wd; }
    void P(const data_t wd) { MPU_DATAPATH(top_, p) = wd; }
    void PCL(const data_t wd) { MPU_DATAPATH(top_, pcl) = wd; }
    void PCH(const data_t wd) { MPU_DATAPATH(top_, pch) = wd; }
    void PC(const addr_t wd) { PCL(wd & 0xff); PCH((wd >> 8) & 0xff); }
    void IR(const data_t wd) { MPU_TOP(top_, instr) = wd; }

private:

    std::unique_ptr<Vmpu> top_;
    std::unique_ptr<Memory<addr_t, data_t>> mem_;
    std::unique_ptr<VerilatedVcdC> vcd_;
    const char *vcd_file_;
    const bool verbose_;

    int time_;

#undef MPU_TOP
#undef MPU_CONTROLLER
#undef MPU_DATAPATH
};


int main(int argc, char **argv)
{
    // Intialize Verilated
    Verilated::commandArgs(argc, argv);

    // Create testbench
    auto tb = std::make_unique<TestBench>("sim_mpu.vcd");

    // Read test config yaml file
    const auto test_patterns = YAML::LoadFile("sim_mpu.yml");

    // Load memory vector from yaml file function
    auto load_mem = [](const YAML::Node& mem_node) {
        std::vector<std::tuple<TestBench::addr_t, TestBench::data_t>> ret;
        for (const auto& mem : mem_node) {
            const auto addr = mem.first.as<int>();
            const auto data = mem.second.as<int>();
            ret.emplace_back(
                std::tuple<TestBench::addr_t, TestBench::data_t>(addr, data));
        }
        return ret;
    };

    // Run tests from yaml file
    for (const auto& op : test_patterns) {
        const auto op_name = op["name"].as<std::string>();

        for (const auto& mode : op["mode"]) {
            const auto mode_name = mode["name"].as<std::string>();

            // Execute a test pattern
            const auto& input = mode["input"];
            tb->Reset(
                load_mem(input["mem"]),
                input["reg"]["A"].as<int>(),
                input["reg"]["X"].as<int>(),
                input["reg"]["Y"].as<int>(),
                input["reg"]["S"].as<int>(),
                input["reg"]["P"].as<int>(),
                input["reg"]["AB"].as<int>(),
                input["reg"]["PC"].as<int>()
            );
            tb->Run(mode["cycle"].as<int>());

            // Verify the test
            const auto& expected = mode["expected"];
            const auto is_valid = tb->Verify(
                load_mem(expected["mem"]),
                expected["reg"]["A"].as<int>(),
                expected["reg"]["X"].as<int>(),
                expected["reg"]["Y"].as<int>(),
                expected["reg"]["S"].as<int>(),
                expected["reg"]["P"].as<int>(),
                expected["reg"]["AB"].as<int>(),
                expected["reg"]["PC"].as<int>()
            );

            std::cout << (is_valid ? "Success" : "   Fail") << ": "
                      << op_name << ": "
                      << mode_name << std::endl;
        }
    }

    return 0;
}
