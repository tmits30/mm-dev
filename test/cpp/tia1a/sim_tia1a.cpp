//------------------------------------------------------------------------------
// Simlation for Television Interface Adaptor (Model 1A)
//------------------------------------------------------------------------------

#include <fstream>
#include <iomanip>
#include <iostream>
#include <fstream>
#include <map>
#include <memory>

#include <yaml-cpp/yaml.h>

#include "verilated_vcd_c.h"
#include "Vtia1a.h"


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
#define TIA1A_TOP(ptr, element) \
    (ptr)->tia1a__DOT__##element

public:

    //--------------------------------------------------------------------------
    // Helper class
    //--------------------------------------------------------------------------

    struct ModuleValues
    {
        using value_type = int;

        ModuleValues(
            const std::vector<std::string>& names, const YAML::Node& nodes)
        {
            // Initialize to zero
            for (const auto& name : names) {
                values_.emplace(name, 0);
            }
            // Set values from yaml
            for (const auto& node : nodes) {
                const auto& name = node.first.as<std::string>();
                const auto& value = node.second.as<value_type>();
                values_[name] = value;
            }
        }

        value_type operator()(const std::string& name) const
        {
            return values_.at(name);
        }

        std::map<std::string, value_type> values_;
    };

    struct Inputs : public ModuleValues
    {
        Inputs(const YAML::Node& nodes) :
            ModuleValues(GetNames(), nodes)
        {}

        const std::vector<std::string> GetNames() const
        {
            return {
                "DEL", "R_W", "CS", "A", "I", "D_IN"
            };
        }
    };

    struct Outputs : public ModuleValues
    {
        Outputs(const YAML::Node& nodes) :
            ModuleValues(GetNames(), nodes)
        {}

        const std::vector<std::string> GetNames() const
        {
            return {
                "HSYNC", "HBLANK", "VSYNC", "VBLANK",
                "RDY", "LUM", "COL", "AUD", "D_OUT"
            };
        }
    };

    struct Registers : public ModuleValues
    {
        Registers(const YAML::Node& nodes) :
            ModuleValues(GetNames(), nodes)
        {}

        const std::vector<std::string> GetNames() const
        {
            return {
                "VSYNC", "VBLANK", "NUSIZ0", "NUSIZ1",
                "COLUP0", "COLUP1", "COLUPF", "COLUBK", "CTRLPF",
                "REFP0", "REFP1", "PF0", "PF1", "PF2",
                "GRP0", "GRP1", "GRP0D", "GRP1D",
                "ENAM0", "ENAM1", "ENABL", "ENABLD",
                "HMP0", "HMP1", "HMM0", "HMM1", "HMBL",
                "POSP0", "POSP1", "POSM0", "POSM1", "POSBL",
                "VDELP0", "VDELP1", "VDELBL",
                "RESMP0", "RESMP1", "CXCLR", "CXR",
                // Sub registers
                "HCOUNT", "PIXEL"
            };
        }
    };

    const int PERIOD = 1;

    TestBench(const char *vcd_file = nullptr, const bool verbose = false) :
        top_(std::make_unique<Vtia1a>("top")),
        vcd_(std::make_unique<VerilatedVcdC>()),
        vcd_file_(vcd_file),
        verbose_(verbose),
        vcd_time_(0)
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

    void Reset(const Registers& regs)
    {
        // Reset
        RES_N(0); CCLK(0);
        const auto end_clk = (PERIOD * 2) * 1;
        for (auto i = decltype(end_clk)(0); i < end_clk; ++i) {
            if ((i % PERIOD) == 0) {
                CCLK(!CCLK());
            }
            top_->eval();
        }

        // Set register
        RES_N(1); CCLK(1); MCLK(1);
        SetRegisters(regs);
    }

    void Run(const int cycles, const std::map<int, Inputs>& inputs,
             const std::string& screen_name = "")
    {
        constexpr int CCLK_PER_MCLK = 3;

        std::ofstream screen;
        if (screen_name.length() > 0) {
            screen.open(screen_name, std::ios::out | std::ios::binary);
        }

        int clock = 0;
        const auto end_time = PERIOD * (2 * (cycles + 1) + 1);
        for (auto time = decltype(end_time)(0); time < end_time; ++time) {
            // Dump signals
            if (vcd_file_) {
                vcd_->dump(vcd_time_);
            }

            // Execute
            if (((time + 1) % PERIOD) == 0) {
                CCLK(!CCLK());
                clock += CCLK();
            }
            if (((time + 1) % (PERIOD * CCLK_PER_MCLK)) == 0) {
                MCLK(!MCLK());
            }
            top_->eval();

            const auto it = inputs.find(clock);
            if (it != inputs.end()) {
                const auto inputs = it->second;
                SetInputs(inputs);
            }
            top_->eval();

            vcd_time_ += 1;

            if ((HCOUNT_REG() >= 68) && CCLK()) {
                uint8_t pixel_value = (COL() << 4) | (LUM() << 1);
                screen.write(
                    reinterpret_cast<char *>(&pixel_value), sizeof(char));
            }
        }

        if (screen_name.length() > 0) {
            screen.close();
        }
    }

    bool Verify(const Outputs& outputs, const Registers& regs)
    {
        bool ret = true;

        auto error_log = [](const int e, const int a, const int d = 2) {
            std::stringstream ret;
            ret << " (expected " << HexString(e, d)
                << ", actual " << HexString(a, d) << ")";
            return ret.str();
        };

        // Verify register
        auto verify_func = [&ret, &error_log](
            const int e, const int a, const std::string name) {
            if (e != a) {
                ret = false;
                std::cout << "error: " << name << error_log(e, a) << std::endl;
            }
        };

        // For outputs
        verify_func(outputs("HSYNC"), HSYNC(), "HSYNC");
        verify_func(outputs("HBLANK"), HBLANK(), "HBLANK");
        verify_func(outputs("VSYNC"), VSYNC(), "VSYNC");
        verify_func(outputs("VBLANK"), VBLANK(), "VBLANK");
        verify_func(outputs("RDY"), RDY(), "RDY");
        verify_func(outputs("LUM"), LUM(), "LUM");
        verify_func(outputs("COL"), COL(), "COL");
        verify_func(outputs("AUD"), AUD(), "AUD");
        verify_func(outputs("D_OUT"), D_OUT(), "D_OUT");

        //For registers
        verify_func(regs("VSYNC"), VSYNC_REG(), "VSYNC");
        verify_func(regs("VBLANK"), VBLANK_REG(), "VBLANK");
        verify_func(regs("NUSIZ0"), NUSIZ0_REG(), "NUSIZ0");
        verify_func(regs("NUSIZ1"), NUSIZ1_REG(), "NUSIZ1");
        verify_func(regs("COLUP0"), COLUP0_REG(), "COLUP0");
        verify_func(regs("COLUP1"), COLUP1_REG(), "COLUP1");
        verify_func(regs("COLUPF"), COLUPF_REG(), "COLUPF");
        verify_func(regs("COLUBK"), COLUBK_REG(), "COLUBK");
        verify_func(regs("CTRLPF"), CTRLPF_REG(), "CTRLPF");
        verify_func(regs("REFP0"), REFP0_REG(), "REFP0");
        verify_func(regs("REFP1"), REFP1_REG(), "REFP1");
        verify_func(regs("PF0"), PF0_REG(), "PF0");
        verify_func(regs("PF1"), PF1_REG(), "PF1");
        verify_func(regs("PF2"), PF2_REG(), "PF2");
        verify_func(regs("GRP0"), GRP0_REG(), "GRP0");
        verify_func(regs("GRP1"), GRP1_REG(), "GRP1");
        verify_func(regs("GRP0D"), GRP0D_REG(), "GRP0D");
        verify_func(regs("GRP1D"), GRP1D_REG(), "GRP1D");
        verify_func(regs("ENAM0"), ENAM0_REG(), "ENAM0");
        verify_func(regs("ENAM1"), ENAM1_REG(), "ENAM1");
        verify_func(regs("ENABL"), ENABL_REG(), "ENABL");
        verify_func(regs("ENABLD"), ENABLD_REG(), "ENABLD");
        verify_func(regs("HMP0"), HMP0_REG(), "HMP0");
        verify_func(regs("HMP1"), HMP1_REG(), "HMP1");
        verify_func(regs("HMM0"), HMM0_REG(), "HMM0");
        verify_func(regs("HMM1"), HMM1_REG(), "HMM1");
        verify_func(regs("HMBL"), HMBL_REG(), "HMBL");
        verify_func(regs("POSP0"), POSP0_REG(), "POSP0");
        verify_func(regs("POSP1"), POSP1_REG(), "POSP1");
        verify_func(regs("POSM0"), POSM0_REG(), "POSM0");
        verify_func(regs("POSM1"), POSM1_REG(), "POSM1");
        verify_func(regs("POSBL"), POSBL_REG(), "POSBL");
        verify_func(regs("VDELP0"), VDELP0_REG(), "VDELP0");
        verify_func(regs("VDELP1"), VDELP1_REG(), "VDELP1");
        verify_func(regs("VDELBL"), VDELBL_REG(), "VDELBL");
        verify_func(regs("RESMP0"), RESMP0_REG(), "RESMP0");
        verify_func(regs("RESMP1"), RESMP1_REG(), "RESMP1");
        verify_func(regs("CXCLR"), CXCLR_REG(), "CXCLR");
        verify_func(regs("CXR"), CXR_REG(), "CXR");

        return ret;
    }

    void SetInputs(const Inputs& values)
    {
        DEL(values("DEL"));
        R_W(values("R_W"));
        CS(values("CS"));
        A(values("A"));
        I(values("I"));
        D_IN(values("D_IN"));
    }

    void SetOutputs(const Outputs& values)
    {
        HSYNC(values("HSYNC"));
        HBLANK(values("HBLANK"));
        VSYNC(values("VSYNC"));
        VBLANK(values("VBLANK"));
        RDY(values("RDY"));
        LUM(values("LUM"));
        COL(values("COL"));
        AUD(values("AUD"));
        D_OUT(values("D_OUT"));
    }

    void SetRegisters(const Registers& values)
    {
        VSYNC_REG(values("VSYNC"));
        VBLANK_REG(values("VBLANK"));
        NUSIZ0_REG(values("NUSIZ0"));
        NUSIZ1_REG(values("NUSIZ1"));
        COLUP0_REG(values("COLUP0"));
        COLUP1_REG(values("COLUP1"));
        COLUPF_REG(values("COLUPF"));
        COLUBK_REG(values("COLUBK"));
        CTRLPF_REG(values("CTRLPF"));
        REFP0_REG(values("REFP0"));
        REFP1_REG(values("REFP1"));
        PF0_REG(values("PF0"));
        PF1_REG(values("PF1"));
        PF2_REG(values("PF2"));
        GRP0_REG(values("GRP0"));
        GRP1_REG(values("GRP1"));
        GRP0D_REG(values("GRP0D"));
        GRP1D_REG(values("GRP1D"));
        ENAM0_REG(values("ENAM0"));
        ENAM1_REG(values("ENAM1"));
        ENABL_REG(values("ENABL"));
        ENABLD_REG(values("ENABLD"));
        HMP0_REG(values("HMP0"));
        HMP1_REG(values("HMP1"));
        HMM0_REG(values("HMM0"));
        HMM1_REG(values("HMM1"));
        HMBL_REG(values("HMBL"));
        POSP0_REG(values("POSP0"));
        POSP1_REG(values("POSP1"));
        POSM0_REG(values("POSM0"));
        POSM1_REG(values("POSM1"));
        POSBL_REG(values("POSBL"));
        VDELP0_REG(values("VDELP0"));
        VDELP1_REG(values("VDELP1"));
        VDELBL_REG(values("VDELBL"));
        RESMP0_REG(values("RESMP0"));
        RESMP1_REG(values("RESMP1"));
        CXCLR_REG(values("CXCLR"));
        CXR_REG(values("CXR"));

        HCOUNT_REG(values("HCOUNT"));
        PIXEL_REG(values("PIXEL"));
    }

    // Getter and Setter
#define DECL_ACCESSOR(type, func, var) \
    type func() { return var; } \
    const type func() const { return var; } \
    void func(const type wd) { var = wd; }

    // Accessor for inputs
    DECL_ACCESSOR(uint8_t, MCLK, top_->MCLK);     // 1-bit
    DECL_ACCESSOR(uint8_t, CCLK, top_->CCLK);     // 1-bit
    DECL_ACCESSOR(uint8_t, RES_N, top_->RES_N);   // 1-bit
    DECL_ACCESSOR(uint8_t, DEL, top_->DEL);       // 1-bit
    DECL_ACCESSOR(uint8_t, R_W, top_->R_W);       // 1-bit
    DECL_ACCESSOR(uint8_t, CS, top_->CS);         // 4-bit
    DECL_ACCESSOR(uint8_t, A, top_->A);           // 6-bit
    DECL_ACCESSOR(uint8_t, I, top_->I);           // 6-bit
    DECL_ACCESSOR(uint8_t, D_IN, top_->D_IN);     // 8-bit

    // Accessor for outputs
    DECL_ACCESSOR(uint8_t, RDY, top_->RDY);       // 1-bit
    DECL_ACCESSOR(uint8_t, HSYNC, top_->HSYNC);   // 1-bit
    DECL_ACCESSOR(uint8_t, HBLANK, top_->HBLANK); // 1-bit
    DECL_ACCESSOR(uint8_t, VSYNC, top_->VSYNC);   // 1-bit
    DECL_ACCESSOR(uint8_t, VBLANK, top_->VBLANK); // 1-bit
    DECL_ACCESSOR(uint8_t, LUM, top_->LUM);       // 3-bit
    DECL_ACCESSOR(uint8_t, COL, top_->COL);       // 4-bit
    DECL_ACCESSOR(uint8_t, AUD, top_->AUD);       // 2-bit
    DECL_ACCESSOR(uint8_t, D_OUT, top_->D_OUT);   // 8-bit

    // Accessor for internal registers
    DECL_ACCESSOR(uint8_t, VSYNC_REG, TIA1A_TOP(top_, vsync));     // 1-bit
    DECL_ACCESSOR(uint8_t, VBLANK_REG, TIA1A_TOP(top_, vblank));   // 8-bit
    DECL_ACCESSOR(uint8_t, NUSIZ0_REG, TIA1A_TOP(top_, nusiz0));   // 8-bit
    DECL_ACCESSOR(uint8_t, NUSIZ1_REG, TIA1A_TOP(top_, nusiz1));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUP0_REG, TIA1A_TOP(top_, colup0));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUP1_REG, TIA1A_TOP(top_, colup1));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUPF_REG, TIA1A_TOP(top_, colupf));   // 8-bit
    DECL_ACCESSOR(uint8_t, COLUBK_REG, TIA1A_TOP(top_, colubk));   // 8-bit
    DECL_ACCESSOR(uint8_t, CTRLPF_REG, TIA1A_TOP(top_, ctrlpf));   // 8-bit
    DECL_ACCESSOR(uint8_t, REFP0_REG, TIA1A_TOP(top_, refp0));     // 1-bit
    DECL_ACCESSOR(uint8_t, REFP1_REG, TIA1A_TOP(top_, refp1));     // 1-bit
    DECL_ACCESSOR(uint8_t, PF0_REG, TIA1A_TOP(top_, pf0));         // 8-bit
    DECL_ACCESSOR(uint8_t, PF1_REG, TIA1A_TOP(top_, pf1));         // 8-bit
    DECL_ACCESSOR(uint8_t, PF2_REG, TIA1A_TOP(top_, pf2));         // 8-bit
    DECL_ACCESSOR(uint8_t, GRP0_REG, TIA1A_TOP(top_, grp0));       // 8-bit
    DECL_ACCESSOR(uint8_t, GRP1_REG, TIA1A_TOP(top_, grp1));       // 8-bit
    DECL_ACCESSOR(uint8_t, GRP0D_REG, TIA1A_TOP(top_, grp0d));     // 8-bit
    DECL_ACCESSOR(uint8_t, GRP1D_REG, TIA1A_TOP(top_, grp1d));     // 8-bit
    DECL_ACCESSOR(uint8_t, ENAM0_REG, TIA1A_TOP(top_, enam0));     // 1-bit
    DECL_ACCESSOR(uint8_t, ENAM1_REG, TIA1A_TOP(top_, enam1));     // 1-bit
    DECL_ACCESSOR(uint8_t, ENABL_REG, TIA1A_TOP(top_, enabl));     // 1-bit
    DECL_ACCESSOR(uint8_t, ENABLD_REG, TIA1A_TOP(top_, enabld));   // 1-bit
    DECL_ACCESSOR(uint8_t, HMP0_REG, TIA1A_TOP(top_, hmp0));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMP1_REG, TIA1A_TOP(top_, hmp1));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMM0_REG, TIA1A_TOP(top_, hmm0));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMM1_REG, TIA1A_TOP(top_, hmm1));       // 8-bit
    DECL_ACCESSOR(uint8_t, HMBL_REG, TIA1A_TOP(top_, hmbl));       // 8-bit
    DECL_ACCESSOR(uint8_t, POSP0_REG, TIA1A_TOP(top_, posp0));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSP1_REG, TIA1A_TOP(top_, posp1));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSM0_REG, TIA1A_TOP(top_, posm0));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSM1_REG, TIA1A_TOP(top_, posm1));     // 8-bit
    DECL_ACCESSOR(uint8_t, POSBL_REG, TIA1A_TOP(top_, posbl));     // 8-bit
    DECL_ACCESSOR(uint8_t, VDELP0_REG, TIA1A_TOP(top_, vdelp0));   // 1-bit
    DECL_ACCESSOR(uint8_t, VDELP1_REG, TIA1A_TOP(top_, vdelp1));   // 1-bit
    DECL_ACCESSOR(uint8_t, VDELBL_REG, TIA1A_TOP(top_, vdelbl));   // 1-bit
    DECL_ACCESSOR(uint8_t, RESMP0_REG, TIA1A_TOP(top_, resmp0));   // 1-bit
    DECL_ACCESSOR(uint8_t, RESMP1_REG, TIA1A_TOP(top_, resmp1));   // 1-bit
    DECL_ACCESSOR(uint8_t, CXCLR_REG, TIA1A_TOP(top_, cxclr));     // 1-bit
    DECL_ACCESSOR(uint16_t, CXR_REG, TIA1A_TOP(top_, cxr));        // 15-bit

    DECL_ACCESSOR(uint8_t, HCOUNT_REG, TIA1A_TOP(top_, hcount));   // 8-bit
    DECL_ACCESSOR(uint8_t, PIXEL_REG, TIA1A_TOP(top_, pixel));     // 8-bit
    DECL_ACCESSOR(uint8_t, WSYNC_REG, TIA1A_TOP(top_, wsync));     // 1-bit
    DECL_ACCESSOR(uint8_t, GRP0__REG, TIA1A_TOP(top_, grp0_));     // 8-bit
    DECL_ACCESSOR(uint8_t, GRP1__REG, TIA1A_TOP(top_, grp1_));     // 8-bit
    DECL_ACCESSOR(uint8_t, GRM0__REG, TIA1A_TOP(top_, grm0_));     // 8-bit
    DECL_ACCESSOR(uint8_t, GRM1__REG, TIA1A_TOP(top_, grm1_));     // 8-bit
    DECL_ACCESSOR(uint8_t, GRBL__REG, TIA1A_TOP(top_, grbl_));     // 8-bit
    DECL_ACCESSOR(uint8_t, DOTPF_REG, TIA1A_TOP(top_, dotpf));     // 1-bit
    DECL_ACCESSOR(uint8_t, DOTP0_REG, TIA1A_TOP(top_, dotp0));     // 1-bit
    DECL_ACCESSOR(uint8_t, DOTP1_REG, TIA1A_TOP(top_, dotp1));     // 1-bit
    DECL_ACCESSOR(uint8_t, DOTM0_REG, TIA1A_TOP(top_, dotm0));     // 1-bit
    DECL_ACCESSOR(uint8_t, DOTM1_REG, TIA1A_TOP(top_, dotm1));     // 1-bit
    DECL_ACCESSOR(uint8_t, DOTBL_REG, TIA1A_TOP(top_, dotbl));     // 1-bit
    DECL_ACCESSOR(uint8_t, COLUPF__REG, TIA1A_TOP(top_, colupf_)); // 8-bit
    DECL_ACCESSOR(uint8_t, COLUPX_REG, TIA1A_TOP(top_, colupx));   // 8-bit
    DECL_ACCESSOR(uint8_t, INPTD_REG, TIA1A_TOP(top_, inptd));     // 4-bit
    DECL_ACCESSOR(uint8_t, INPTL__REG, TIA1A_TOP(top_, inptl_));   // 2-bit
    DECL_ACCESSOR(uint8_t, INPTL_REG, TIA1A_TOP(top_, inptl));     // 2-bit

#undef DECL_ACCESSOR

private:

    std::unique_ptr<Vtia1a> top_;
    std::unique_ptr<VerilatedVcdC> vcd_;
    const char *vcd_file_;
    const bool verbose_;

    int vcd_time_;

#undef TIA1A_TOP
};


int main(int argc, char **argv)
{
    // Intialize Verilated
    Verilated::commandArgs(argc, argv);

    // Create testbench
    auto tb = std::make_unique<TestBench>("sim_tia1a.vcd");

    // Read test config yaml file
    const auto test_patterns = YAML::LoadFile("sim_tia1a.yml");

    // Run tests from yaml file
    for (const auto& target : test_patterns) {
        const auto target_name = target["target"].as<std::string>();

        for (const auto& test : target["tests"]) {
            const auto comment = test["comment"].as<std::string>();

            // Execute a test pattern
            const auto& initial = test["initial"];
            tb->Reset(TestBench::Registers(initial["reg"]));

            // Run
            std::map<int, TestBench::Inputs> inputs;
            for (const auto& input : test["inputs"]) {
                inputs.emplace(
                    input["clock"].as<int>(),
                    TestBench::Inputs(input["in"]));
            }
            if (target_name == "Screen") {
                const auto screen_name = test["screen_name"].as<std::string>();
                tb->Run(test["cycle"].as<int>(), inputs, screen_name);
            } else {
                tb->Run(test["cycle"].as<int>(), inputs);
            }

            // Verify the test
            const auto& expected = test["expected"];
            const auto is_valid = tb->Verify(
                TestBench::Outputs(expected["out"]),
                TestBench::Registers(expected["reg"]));

            std::cout << (is_valid ? "Success" : "   Fail") << ": "
                      << target_name << ": "
                      << comment << std::endl;
        }
    }

    return 0;
}
