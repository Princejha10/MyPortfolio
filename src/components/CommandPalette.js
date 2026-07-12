"use client";
import { useEffect, useState } from "react";
import { Search, FolderGit, Terminal, Compass, Briefcase, FileText, Phone, Github } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

export default function CommandPalette({ isOpen, onClose }) {
  const [search, setSearch] = useState("");

  useEffect(() => {
    const handleKeyDown = (e) => {
      // Toggle on Ctrl+K / Cmd+K
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault();
        if (isOpen) onClose();
        else onClose(true); // signals parent to open
      }
      // Close on Esc
      if (e.key === "Escape" && isOpen) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  const items = [
    { name: "Go to Projects", desc: "Browse mobile & web portfolio projects", category: "Navigation", shortcut: "G P", icon: <FolderGit className="w-4 h-4 text-[#FF2B2B]" />, action: () => handleScrollTo("#projects") },
    { name: "Go to Tech Stack", desc: "View categorized technologies and tools", category: "Navigation", shortcut: "G S", icon: <Terminal className="w-4 h-4 text-[#FF2B2B]" />, action: () => handleScrollTo("#tech-stack") },
    { name: "Go to About", desc: "Inspect B.Tech timelines and focus focus points", category: "Navigation", shortcut: "G A", icon: <Compass className="w-4 h-4 text-[#FF2B2B]" />, action: () => handleScrollTo("#about") },
    { name: "Go to Experience", desc: "Review IT Intern milestones and credentials", category: "Navigation", shortcut: "G E", icon: <Briefcase className="w-4 h-4 text-[#FF2B2B]" />, action: () => handleScrollTo("#experience") },
    { name: "Download Resume", desc: "Retrieve PDF curriculum vitae", category: "Actions", shortcut: "D R", icon: <FileText className="w-4 h-4 text-[#FF2B2B]" />, action: () => window.open("/resume.pdf", "_blank") },
    { name: "Get in Touch", desc: "Establish connection parameters via message form", category: "Actions", shortcut: "G T", icon: <Phone className="w-4 h-4 text-[#FF2B2B]" />, action: () => handleScrollTo("#contact") },
    { name: "View GitHub Source", desc: "Inspect public archive profiles", category: "External", shortcut: "G H", icon: <Github className="w-4 h-4 text-white/40" />, action: () => window.open("https://github.com/Princejha10", "_blank") }
  ];

  const handleScrollTo = (id) => {
    onClose();
    const element = document.querySelector(id);
    if (element) {
      setTimeout(() => {
        element.scrollIntoView({ behavior: "smooth" });
      }, 100);
    }
  };

  const filteredItems = items.filter(
    (item) =>
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      item.desc.toLowerCase().includes(search.toLowerCase()) ||
      item.category.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-start justify-center pt-24 px-4">
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-black/80 backdrop-blur-sm"
          />

          {/* Modal Container */}
          <motion.div
            initial={{ opacity: 0, y: -20, scale: 0.97 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -20, scale: 0.97 }}
            transition={{ duration: 0.2 }}
            className="relative z-10 w-full max-w-xl bg-[#0A0A0A]/95 backdrop-blur-xl border border-white/5 rounded-3xl overflow-hidden shadow-2xl"
          >
            {/* Search Input bar */}
            <div className="flex items-center gap-3 px-4 py-3.5 border-b border-white/5">
              <Search className="w-5 h-5 text-[#A3A3A3]" />
              <input
                type="text"
                placeholder="Search commands..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="flex-1 bg-transparent text-xs text-white placeholder-white/30 focus:outline-none"
                autoFocus
              />
              <kbd className="hidden sm:inline-block font-mono text-[9px] text-[#A3A3A3] bg-white/5 border border-white/5 px-1.5 py-0.5 rounded uppercase">
                ESC
              </kbd>
            </div>

            {/* Command List items */}
            <div className="max-h-[300px] overflow-y-auto p-2 space-y-4">
              {filteredItems.length === 0 ? (
                <div className="py-8 text-center text-[10px] font-mono text-[#A3A3A3]">
                  NO COMMANDS MATCHED YOUR SEARCH.
                </div>
              ) : (
                /* Group items by category */
                ["Navigation", "Actions", "External"].map((cat) => {
                  const catItems = filteredItems.filter((i) => i.category === cat);
                  if (catItems.length === 0) return null;

                  return (
                    <div key={cat} className="space-y-1 text-left">
                      <div className="px-3 py-1 font-mono text-[8px] text-white/30 uppercase tracking-widest">
                        {cat}
                      </div>

                      <div className="space-y-0.5">
                        {catItems.map((item) => (
                          <button
                            key={item.name}
                            onClick={item.action}
                            className="w-full flex items-center justify-between gap-4 p-2.5 rounded-xl hover:bg-white/5 transition-colors group cursor-pointer text-left"
                          >
                            <div className="flex items-center gap-3 min-w-0">
                              <div className="p-2 bg-[#050505] rounded-lg border border-white/5 shrink-0">
                                {item.icon}
                              </div>
                              <div className="min-w-0">
                                <div className="text-xs font-semibold text-white group-hover:text-[#FF2B2B] transition-colors uppercase tracking-tight">
                                  {item.name}
                                </div>
                                <div className="text-[10px] text-[#A3A3A3] truncate leading-normal">
                                  {item.desc}
                                </div>
                              </div>
                            </div>
                            <kbd className="hidden sm:inline-block font-mono text-[8px] text-[#A3A3A3] bg-white/5 border border-white/5 px-2 py-0.5 rounded">
                              {item.shortcut}
                            </kbd>
                          </button>
                        ))}
                      </div>
                    </div>
                  );
                })
              )}
            </div>

            {/* Footer tip */}
            <div className="bg-[#111111] px-4 py-2.5 border-t border-white/5 flex items-center justify-between text-[8px] font-mono text-white/30">
              <span>USE MOUSE OR SHORTCUTS TO CHOOSE COMMANDS</span>
              <span>ESC TO CLOSE</span>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
