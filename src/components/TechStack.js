"use client";
import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Cpu, Smartphone, Database, Terminal, Shield, Sparkles } from "lucide-react";

export default function TechStack() {
  const [activeCategory, setActiveCategory] = useState("all");

  const categories = [
    { id: "all", name: "All Tech" },
    { id: "frontend", name: "Mobile & Web" },
    { id: "backend", name: "Backend & DBs" },
    { id: "ai", name: "AI & Learning" },
  ];

  const technologies = [
    {
      name: "Flutter & Dart",
      category: "frontend",
      level: "Intermediate",
      desc: "Building cross-platform mobile apps for iOS and Android, focusing on state and performance.",
      icon: <Smartphone className="w-5 h-5 text-[#FF2B2B]" />,
      badgeColor: "text-amber-400 bg-amber-400/5 border-amber-400/10"
    },
    {
      name: "Python & Scripts",
      category: "backend",
      level: "Intermediate",
      desc: "Developing backend logic, scripting, data parsing, and model API invocations.",
      icon: <Terminal className="w-5 h-5 text-[#FF2B2B]" />,
      badgeColor: "text-amber-400 bg-amber-400/5 border-amber-400/10"
    },
    {
      name: "React / Next.js",
      category: "frontend",
      level: "Intermediate",
      desc: "Creating fast, SEO-friendly responsive landing pages, portals, and dashboards.",
      icon: <Smartphone className="w-5 h-5 text-[#FF2B2B]" />,
      badgeColor: "text-amber-400 bg-amber-400/5 border-amber-400/10"
    },
    {
      name: "Firebase Suite",
      category: "backend",
      level: "Intermediate",
      desc: "Firestore document stores, user authentication systems, and cloud storage triggers.",
      icon: <Database className="w-5 h-5 text-[#FF2B2B]" />,
      badgeColor: "text-amber-400 bg-amber-400/5 border-amber-400/10"
    },
    {
      name: "Node.js & Express",
      category: "backend",
      level: "Beginner",
      desc: "Building basic REST endpoints, database connectors, and mock service middleware.",
      icon: <Terminal className="w-5 h-5 text-[#FF2B2B]" />,
      badgeColor: "text-[#A3A3A3] bg-white/5 border-white/5"
    },
    {
      name: "LLMs / Prompt Engineering",
      category: "ai",
      level: "Beginner",
      desc: "Structuring model instructions, token parsing strategies, and system constraints.",
      icon: <Cpu className="w-5 h-5 text-[#FF2B2B]" />,
      badgeColor: "text-[#A3A3A3] bg-white/5 border-white/5"
    },
    {
      name: "LangChain",
      category: "ai",
      level: "Learning",
      desc: "Experimenting with task routing chains, embedding indexes, and multi-agent loops.",
      icon: <Cpu className="w-5 h-5 text-[#FF2B2B]" />,
      badgeColor: "text-[#FF2B2B] bg-[#FF2B2B]/5 border-[#FF2B2B]/10"
    }
  ];

  const filteredTech =
    activeCategory === "all"
      ? technologies
      : technologies.filter((tech) => tech.category === activeCategory);

  return (
    <section id="tech-stack" className="py-24 px-6 md:px-12 max-w-5xl mx-auto w-full relative border-t border-white/5 bg-[#050505]">
      {/* Section Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-16">
        <div className="flex flex-col items-start gap-4 text-left">
          <div className="font-mono text-xs uppercase tracking-widest text-[#FF2B2B] flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[#FF2B2B]" />
            <span>Capability Index</span>
          </div>
          <h2 className="font-heading text-2xl md:text-3xl font-bold tracking-tight text-white uppercase">
            Technical Stack
          </h2>
        </div>

        {/* Categories Tab Selector */}
        <div className="flex flex-wrap gap-2 bg-white/5 border border-white/5 p-1 rounded-xl self-start md:self-end">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setActiveCategory(cat.id)}
              className={`px-3 py-1.5 rounded-lg text-[10px] font-heading font-medium tracking-wide transition-all uppercase ${
                activeCategory === cat.id
                  ? "bg-[#FF2B2B] text-white shadow-lg"
                  : "text-[#A3A3A3] hover:text-white"
              }`}
            >
              {cat.name}
            </button>
          ))}
        </div>
      </div>

      {/* Stack Grid */}
      <motion.div
        layout
        className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6"
      >
        <AnimatePresence mode="popLayout">
          {filteredTech.map((tech, idx) => (
            <motion.div
              layout
              key={tech.name}
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.4, delay: idx * 0.05 }}
              className="bg-[#111111] border border-white/5 rounded-2xl p-6 flex flex-col justify-between hover:border-[#FF2B2B]/20 transition-colors text-left"
            >
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="p-2 rounded-xl bg-white/5">
                    {tech.icon}
                  </div>
                  <span className={`text-[10px] font-mono px-2.5 py-0.5 rounded border uppercase ${tech.badgeColor}`}>
                    {tech.level}
                  </span>
                </div>

                <h3 className="font-heading text-base font-bold text-white mb-2 uppercase">
                  {tech.name}
                </h3>
                <p className="font-sans text-xs text-[#A3A3A3] leading-relaxed">
                  {tech.desc}
                </p>
              </div>
            </motion.div>
          ))}
        </AnimatePresence>
      </motion.div>
    </section>
  );
}
