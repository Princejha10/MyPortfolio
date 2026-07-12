"use client";
import { Cpu, Compass, Layout, Network, Database, Sparkles } from "lucide-react";
import { motion } from "framer-motion";

export default function CurrentFocus() {
  const focusNodes = [
    {
      title: "Agentic AI & Swarms",
      desc: "Developing autonomous multi-agent task execution structures and local memory handoffs.",
      progress: 60,
      status: "ACTIVE RESEARCH",
      statusColor: "text-[#FF2B2B] bg-[#FF2B2B]/5 border-[#FF2B2B]/10",
      icon: <Cpu className="w-5 h-5 text-[#FF2B2B]" />
    },
    {
      title: "LangChain Ecosystem",
      desc: "Configuring stateful prompt routers, structured data extractors, and embedding indexes.",
      progress: 40,
      status: "CORE FOCUS",
      statusColor: "text-[#FF2B2B] bg-[#FF2B2B]/5 border-[#FF2B2B]/10",
      icon: <Network className="w-5 h-5 text-[#FF2B2B]" />
    },
    {
      title: "System Design & Scale",
      desc: "Database storage schemas, API route structures, and distributed state logic.",
      progress: 55,
      status: "DEEP DIVE",
      statusColor: "text-[#FF2B2B] bg-[#FF2B2B]/5 border-[#FF2B2B]/10",
      icon: <Database className="w-5 h-5 text-[#FF2B2B]" />
    },
    {
      title: "Flutter Performance Hooks",
      desc: "Profiling application memory, garbage collection limits, and native rendering speeds.",
      progress: 80,
      status: "PRODUCTION ACTIVE",
      statusColor: "text-[#10B981] bg-[#10B981]/5 border-[#10B981]/10",
      icon: <Layout className="w-5 h-5 text-[#10B981]" />
    }
  ];

  return (
    <section id="focus" className="py-24 px-6 md:px-12 max-w-5xl mx-auto w-full relative border-t border-white/5 bg-[#050505]">
      {/* Header */}
      <div className="flex flex-col items-start gap-4 mb-16 text-left">
        <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
          <span>Current Focus</span>
        </div>
        <h2 className="font-heading text-2xl md:text-3xl font-bold tracking-tight text-white uppercase">
          Learning Roadmap
        </h2>
        <p className="font-sans text-xs md:text-sm text-[#A3A3A3] max-w-xl">
          An overview of active research, framework experiments, and system design explorations I am currently undertaking.
        </p>
      </div>

      {/* Roadmap timeline display */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {focusNodes.map((node, idx) => (
          <div
            key={idx}
            className="bg-[#111111] rounded-[2rem] p-6 md:p-8 border border-white/5 flex flex-col justify-between hover:border-[#FF2B2B]/20 transition-all group relative overflow-hidden"
          >
            {/* Background Glow */}
            <div className="absolute -right-16 -top-16 w-32 h-32 bg-white/2 rounded-full blur-2xl group-hover:bg-[#FF2B2B]/5 transition-colors" />

            <div className="text-left space-y-4">
              <div className="flex items-center justify-between gap-4">
                <div className="p-3 rounded-2xl bg-white/5 border border-white/5">
                  {node.icon}
                </div>
                <span className={`font-mono text-[9px] px-2.5 py-1 rounded-full border uppercase ${node.statusColor}`}>
                  {node.status}
                </span>
              </div>

              <h3 className="font-heading text-base font-bold text-white uppercase tracking-tight">
                {node.title}
              </h3>
              <p className="font-sans text-xs text-[#A3A3A3] leading-relaxed">
                {node.desc}
              </p>
            </div>

            {/* Progress indicators */}
            <div className="space-y-2 mt-8 pt-6 border-t border-white/5">
              <div className="flex justify-between items-center text-[9px] font-mono text-white/40">
                <span>ROADMAP_STAGE_COMPLETION</span>
                <span className="text-white">{node.progress}%</span>
              </div>
              <div className="w-full h-1.5 bg-white/5 rounded-full overflow-hidden relative">
                <motion.div
                  className="h-full bg-[#FF2B2B] rounded-full"
                  initial={{ width: 0 }}
                  whileInView={{ width: `${node.progress}%` }}
                  viewport={{ once: true }}
                  transition={{ duration: 1.2, ease: "easeOut" }}
                />
              </div>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
