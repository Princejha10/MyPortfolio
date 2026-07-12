"use client";
import { motion } from "framer-motion";
import { GitCommit, ArrowDown, Sparkles } from "lucide-react";

export default function Protocol() {
  const timelineNodes = [
    { year: "2024", title: "Started Programming", desc: "Wrote first lines of code in Python, discovering a passion for algorithms and automation." },
    { year: "2024", title: "Built First Project", desc: "Created initial CLI utilities and automation scripts, bridging code to functional execution." },
    { year: "2024", title: "National Hackathons", desc: "Competed in engineering hackathons, designing solutions under pressure and presenting to judges." },
    { year: "2025", title: "AAI IT Internship", desc: "Joined Airports Authority of India as an IT intern, exploring database networks and system logs." },
    { year: "2025", title: "Built FinSense", desc: "Shipped FinSense — an expense monitoring tool parsing SMS context tokens on-device." },
    { year: "2026", title: "Currently Learning AI", desc: "Deep diving into LLM prompt logic, LangChain workflow routing, and autonomous agents." },
  ];

  return (
    <section
      id="timeline"
      className="py-24 px-6 md:px-12 max-w-4xl mx-auto w-full relative border-t border-white/5 bg-[#050505]"
    >
      {/* Section Header */}
      <div className="flex flex-col items-start gap-4 mb-16 text-left">
        <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
          <span>Timeline Flow</span>
        </div>
        <h2 className="font-heading text-2xl md:text-3xl font-bold tracking-tight text-white uppercase">
          Developer Journey
        </h2>
      </div>

      {/* Timeline Layout */}
      <div className="relative border-l border-white/5 ml-4 md:ml-32 space-y-12 text-left">
        {timelineNodes.map((node, idx) => (
          <div key={idx} className="relative pl-8 md:pl-12 group">
            
            {/* Pulsing Year indicator on Left (Desktop) */}
            <div className="absolute right-full mr-8 top-1.5 hidden md:block text-right">
              <span className="font-mono text-xs font-bold text-[#A3A3A3] group-hover:text-[#FF2B2B] transition-colors">
                {node.year}
              </span>
            </div>

            {/* Timeline Dot */}
            <div className="absolute left-0 -translate-x-[9.5px] top-2 z-10 w-4 h-4 rounded-full bg-[#050505] border-2 border-white/10 group-hover:border-[#FF2B2B] flex items-center justify-center transition-colors">
              <div className="w-1.5 h-1.5 rounded-full bg-white/10 group-hover:bg-[#FF2B2B] transition-colors" />
            </div>

            {/* Content card */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true, margin: "-80px" }}
              transition={{ duration: 0.6, ease: "easeOut" }}
              className="space-y-1"
            >
              {/* Year label for Mobile (shows inline) */}
              <span className="font-mono text-[10px] text-[#FF2B2B] md:hidden block mb-1">
                {node.year}
              </span>
              <h3 className="font-heading text-lg font-bold text-white uppercase tracking-tight group-hover:text-[#FF2B2B] transition-colors">
                {node.title}
              </h3>
              <p className="font-sans text-xs md:text-sm text-[#A3A3A3] leading-relaxed max-w-xl">
                {node.desc}
              </p>
            </motion.div>
          </div>
        ))}
      </div>
    </section>
  );
}
