"use client";
import { motion } from "framer-motion";
import { Cpu, Terminal, Layers, Sparkles } from "lucide-react";

export default function Roles() {
  const roleCards = [
    {
      title: "AI Engineer",
      desc: "Architecting autonomous prompt routers, multi-agent frameworks, and vector database query retrievals.",
      icon: <Cpu className="w-5 h-5 text-[#FF2B2B]" />,
      pos: "left"
    },
    {
      title: "Python Developer",
      desc: "Writing production scripts, logs auditors, and cleaning pipelines.",
      icon: <Terminal className="w-5 h-5 text-[#FF2B2B]" />,
      pos: "center"
    },
    {
      title: "Full-Stack Developer",
      desc: "Integrating state controls in Flutter, Next.js page models, and persistent SQLite document adapters.",
      icon: <Layers className="w-5 h-5 text-[#FF2B2B]" />,
      pos: "right"
    }
  ];

  return (
    <section
      id="roles"
      className="relative w-full bg-[#050505] py-24 px-6 md:px-12 max-w-5xl mx-auto border-t border-white/5 overflow-hidden"
    >
      {/* Background glow shadow */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[350px] h-[350px] bg-[#FF2B2B]/5 rounded-full blur-[100px] pointer-events-none" />

      {/* Title */}
      <div className="flex flex-col items-center gap-4 mb-20 text-center">
        <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
          <span>Active Capacity</span>
        </div>
        <h2 className="font-heading text-2xl md:text-3xl font-bold tracking-tight text-white uppercase">
          Engineering Focus
        </h2>
      </div>

      {/* SVG PCB Circuit Traces Background (Exact match to screenshot style) */}
      <div className="absolute inset-0 z-0 pointer-events-none hidden md:block">
        <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg">
          {/* Path to Left (AI Engineer) */}
          <path
            id="pathToLeft"
            d="M512 250 H300 V180 H180"
            fill="none"
            stroke="rgba(255, 43, 43, 0.08)"
            strokeWidth="2"
          />
          {/* Path to Center (Python) */}
          <path
            id="pathToCenter"
            d="M512 250 V320"
            fill="none"
            stroke="rgba(255, 43, 43, 0.08)"
            strokeWidth="2"
          />
          {/* Path to Right (Full-Stack) */}
          <path
            id="pathToRight"
            d="M512 250 H724 V180 H844"
            fill="none"
            stroke="rgba(255, 43, 43, 0.08)"
            strokeWidth="2"
          />

          {/* Animated Glowing pulses flowing along paths (60 FPS CSS-level Motion) */}
          <circle r="3.5" fill="#FF2B2B" className="shadow-[0_0_8px_#FF2B2B]">
            <animateMotion dur="2.5s" repeatCount="indefinite" path="M512 250 H300 V180 H180" />
          </circle>
          <circle r="3.5" fill="#FF2B2B" className="shadow-[0_0_8px_#FF2B2B]">
            <animateMotion dur="1.8s" repeatCount="indefinite" path="M512 250 V320" />
          </circle>
          <circle r="3.5" fill="#FF2B2B" className="shadow-[0_0_8px_#FF2B2B]">
            <animateMotion dur="2.5s" repeatCount="indefinite" path="M512 250 H724 V180 H844" />
          </circle>
        </svg>
      </div>

      {/* Cards Layout grid */}
      <div className="relative z-10 flex flex-col md:grid md:grid-cols-3 gap-12 items-center w-full">
        
        {/* Card 1: AI Engineer (Left node) */}
        <motion.div
          initial={{ opacity: 0, x: -30 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="bg-[#111111] border border-white/5 p-6 rounded-[2rem] w-full text-left md:-translate-y-16 hover:border-[#FF2B2B]/20 transition-all group"
        >
          <div className="p-3 rounded-2xl bg-white/5 w-fit mb-4">
            {roleCards[0].icon}
          </div>
          <h3 className="font-heading text-lg font-bold text-white uppercase tracking-tight mb-2 group-hover:text-[#FF2B2B] transition-colors">
            {roleCards[0].title}
          </h3>
          <p className="font-sans text-xs text-[#A3A3A3] leading-relaxed">
            {roleCards[0].desc}
          </p>
        </motion.div>

        {/* Center Node: Centered glowing ROLES title block */}
        <div className="flex flex-col items-center justify-center py-6">
          <div className="glass-card px-8 py-5 rounded-[2rem] border border-[#FF2B2B]/20 shadow-[0_0_30px_rgba(255,43,43,0.18)] text-3xl font-heading font-extrabold uppercase tracking-widest text-center select-none">
            <span className="text-[#FF2B2B]">ROL</span>
            <span className="text-[#A3A3A3]">ES</span>
          </div>
        </div>

        {/* Card 3: Full-Stack Developer (Right node) */}
        <motion.div
          initial={{ opacity: 0, x: 30 }}
          whileInView={{ opacity: 1, x: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="bg-[#111111] border border-white/5 p-6 rounded-[2rem] w-full text-left md:-translate-y-16 hover:border-[#FF2B2B]/20 transition-all group"
        >
          <div className="p-3 rounded-2xl bg-white/5 w-fit mb-4">
            {roleCards[2].icon}
          </div>
          <h3 className="font-heading text-lg font-bold text-white uppercase tracking-tight mb-2 group-hover:text-[#FF2B2B] transition-colors">
            {roleCards[2].title}
          </h3>
          <p className="font-sans text-xs text-[#A3A3A3] leading-relaxed">
            {roleCards[2].desc}
          </p>
        </motion.div>

        {/* Card 2: Python Developer (Center-bottom node) */}
        <div className="col-span-3 flex justify-center w-full mt-4 md:-mt-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6 }}
            className="bg-[#111111] border border-white/5 p-6 rounded-[2rem] w-full max-w-sm text-left hover:border-[#FF2B2B]/20 transition-all group"
          >
            <div className="p-3 rounded-2xl bg-white/5 w-fit mb-4">
              {roleCards[1].icon}
            </div>
            <h3 className="font-heading text-lg font-bold text-white uppercase tracking-tight mb-2 group-hover:text-[#FF2B2B] transition-colors">
              {roleCards[1].title}
            </h3>
            <p className="font-sans text-xs text-[#A3A3A3] leading-relaxed">
              {roleCards[1].desc}
            </p>
          </motion.div>
        </div>

      </div>
    </section>
  );
}
