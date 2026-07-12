"use client";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Github, ExternalLink, Sparkles, BookOpen, X, Code, Shield, HelpCircle, Layers } from "lucide-react";

export default function Projects() {
  const [selectedProject, setSelectedProject] = useState(null);

  const projects = [
    {
      title: "FinSense",
      category: "Flutter Mobile App",
      desc: "Automated expense monitoring parsing device notifications and SMS triggers securely on-device.",
      image: "https://images.unsplash.com/photo-1559526324-4b87b5e36e44?q=80&w=1200",
      problem: "Traditional expense managers require tedious manual entries or require linking direct bank accounts, which compromises user security and privacy.",
      solution: "Built a fully sandboxed local Flutter application that intercepts incoming transaction SMS notifications and parses currency, merchant, and debit/credit states instantly on-device.",
      features: [
        "On-device message parser (Zero internet required)",
        "Local Hive persistent object database",
        "Sleek charts and monthly expense categorization",
        "Secure backup and encrypted CSV data exports"
      ],
      techStack: ["Flutter", "Dart", "Hive DB", "Provider"],
      architecture: "Bloc state routing pattern separating message interceptor streams from the localized repository storage layers.",
      process: "Conducted testing on regex parse speeds for 10+ standard banking message layouts, configured local schema adapters for Hive DB, and implemented dynamic chart components.",
      github: "https://github.com/Princejha10/FinSense",
      demo: "https://github.com/Princejha10/FinSense"
    },
    {
      title: "AAI Log Audit Pipeline",
      category: "IT Automation",
      desc: "Database log aggregator and formatter built to audit security traffic and anomalies.",
      image: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?q=80&w=1200",
      problem: "At Airports Authority of India, auditing database events and network access requests manually was labor-intensive and delayed identifying security vulnerabilities.",
      solution: "Developed a Python utility pipeline that processes large log files, formats data records into clean structures, and detects access patterns violating system policies.",
      features: [
        "Concurrent log stream file reader",
        "Automated PDF & Excel report generation",
        "SQLite historical access index engines",
        "Custom rule-based anomaly detection algorithms"
      ],
      techStack: ["Python", "Pandas", "SQLite", "OpenPyXL"],
      architecture: "Modular piping design parsing files through cleaning and aggregation filters before writing to SQLite and exporting reports.",
      process: "Built optimization filters for parsing lines containing complex system events, designed SQLite indices to run query analysis under 2 seconds, and automated PDF export cycles.",
      github: "https://github.com/Princejha10",
      demo: "https://github.com/Princejha10"
    }
  ];

  return (
    <section id="projects" className="py-24 px-6 md:px-12 max-w-6xl mx-auto w-full relative border-t border-white/5 bg-[#050505]">
      {/* Section Header */}
      <div className="flex flex-col items-start gap-4 mb-16 text-left">
        <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
          <span>Case Studies</span>
        </div>
        <h2 className="font-heading text-2xl md:text-3xl font-bold tracking-tight text-white uppercase">
          Featured Projects
        </h2>
      </div>

      {/* Projects Timeline Stack */}
      <div className="space-y-28">
        {projects.map((proj, idx) => {
          const isEven = idx % 2 === 0;
          return (
            <div
              key={proj.title}
              className={`flex flex-col lg:flex-row items-center gap-12 lg:gap-16 text-left ${
                isEven ? "" : "lg:flex-row-reverse"
              }`}
            >
              {/* Image Container with Hover Scale */}
              <div className="w-full lg:w-1/2 relative group rounded-[1.5rem] overflow-hidden border border-white/5 bg-[#111111]">
                <div className="absolute inset-0 bg-gradient-to-t from-[#050505]/80 via-transparent to-transparent z-10 pointer-events-none" />
                <img
                  src={proj.image}
                  alt={proj.title}
                  className="w-full aspect-[16/10] object-cover filter grayscale contrast-125 group-hover:scale-105 transition-transform duration-500"
                />
              </div>

              {/* Info Area */}
              <div className="w-full lg:w-1/2 space-y-4">
                <span className="font-mono text-[10px] text-[#FF2B2B] uppercase tracking-wider">
                  {proj.category}
                </span>
                <h3 className="font-heading text-3xl font-bold text-white uppercase tracking-tight">
                  {proj.title}
                </h3>
                <p className="font-sans text-sm text-[#A3A3A3] leading-relaxed">
                  {proj.desc}
                </p>

                {/* Tags */}
                <div className="flex flex-wrap gap-2 pt-2">
                  {proj.techStack.map((tech) => (
                    <span
                      key={tech}
                      className="font-mono text-[9px] text-white px-2 py-0.5 rounded bg-white/5 border border-white/5"
                    >
                      {tech}
                    </span>
                  ))}
                </div>

                {/* Actions */}
                <div className="flex flex-wrap items-center gap-4 pt-6">
                  <button
                    onClick={() => setSelectedProject(proj)}
                    className="magnetic-btn group bg-white/5 hover:bg-white/10 text-white text-xs font-heading font-semibold py-3 px-6 rounded-full flex items-center gap-2 border border-white/5"
                  >
                    <BookOpen className="w-4 h-4 text-[#FF2B2B]" />
                    <span>Case Study</span>
                  </button>

                  <a
                    href={proj.github}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="p-3 rounded-full bg-white/5 border border-white/5 text-[#A3A3A3] hover:text-white hover:bg-white/10 transition-colors lift-hover"
                  >
                    <Github className="w-4 h-4" />
                  </a>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Case Study Details Modal (Slide Drawer) */}
      <AnimatePresence>
        {selectedProject && (
          <>
            {/* Backdrop overlay */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setSelectedProject(null)}
              className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm"
            />

            {/* Slide-out Drawer */}
            <motion.div
              initial={{ x: "100%" }}
              animate={{ x: 0 }}
              exit={{ x: "100%" }}
              transition={{ type: "spring", damping: 30, stiffness: 200 }}
              className="fixed right-0 top-0 bottom-0 z-50 w-full max-w-xl bg-[#0A0A0A] border-l border-white/5 p-8 md:p-12 overflow-y-auto scrollbar-none shadow-2xl text-left"
            >
              {/* Close Button */}
              <div className="flex justify-between items-center mb-8">
                <span className="font-mono text-[10px] text-[#FF2B2B] uppercase tracking-wider">
                  Case File // {selectedProject.title}
                </span>
                <button
                  onClick={() => setSelectedProject(null)}
                  className="p-2 rounded-full bg-white/5 text-[#A3A3A3] hover:text-white transition-colors border border-white/5"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              {/* Title & Desc */}
              <div className="space-y-4 mb-8">
                <h3 className="font-heading text-4xl font-extrabold text-white uppercase tracking-tight">
                  {selectedProject.title}
                </h3>
                <span className="inline-block font-mono text-[10px] bg-[#FF2B2B]/10 text-[#FF2B2B] px-2.5 py-0.5 rounded border border-[#FF2B2B]/20">
                  {selectedProject.category}
                </span>
              </div>

              {/* Detailed Content grid */}
              <div className="space-y-6">
                {/* Section 1: Problem */}
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-xs font-mono text-white uppercase font-bold">
                    <HelpCircle className="w-4 h-4 text-[#FF2B2B]" />
                    <span>The Problem</span>
                  </div>
                  <p className="font-sans text-xs md:text-sm text-[#A3A3A3] leading-relaxed">
                    {selectedProject.problem}
                  </p>
                </div>

                {/* Section 2: Solution */}
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-xs font-mono text-white uppercase font-bold">
                    <Shield className="w-4 h-4 text-[#FF2B2B]" />
                    <span>The Solution</span>
                  </div>
                  <p className="font-sans text-xs md:text-sm text-[#A3A3A3] leading-relaxed">
                    {selectedProject.solution}
                  </p>
                </div>

                {/* Section 3: Key Features */}
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-xs font-mono text-white uppercase font-bold">
                    <Code className="w-4 h-4 text-[#FF2B2B]" />
                    <span>Key Features</span>
                  </div>
                  <ul className="space-y-2 pl-4 list-disc text-xs text-[#A3A3A3]">
                    {selectedProject.features.map((feat, idx) => (
                      <li key={idx} className="leading-relaxed">
                        {feat}
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Section 4: Architecture */}
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-xs font-mono text-white uppercase font-bold">
                    <Layers className="w-4 h-4 text-[#FF2B2B]" />
                    <span>System Architecture</span>
                  </div>
                  <p className="font-sans text-xs md:text-sm text-[#A3A3A3] leading-relaxed">
                    {selectedProject.architecture}
                  </p>
                </div>

                {/* Section 5: Development Process */}
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-xs font-mono text-white uppercase font-bold">
                    <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
                    <span>Development Process</span>
                  </div>
                  <p className="font-sans text-xs md:text-sm text-[#A3A3A3] leading-relaxed">
                    {selectedProject.process}
                  </p>
                </div>
              </div>

              {/* Action bar inside drawer */}
              <div className="flex items-center gap-4 mt-12 pt-8 border-t border-white/5">
                <a
                  href={selectedProject.github}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="magnetic-btn bg-[#FF2B2B] text-white text-xs font-heading font-medium tracking-widest uppercase py-3.5 px-6 rounded-full flex items-center justify-center gap-2"
                >
                  Code Base <Github className="w-4 h-4" />
                </a>
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </section>
  );
}
