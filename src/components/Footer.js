"use client";
import { Terminal, ArrowUp } from "lucide-react";

export default function Footer() {
  const handleScrollToTop = (e) => {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handleScrollTo = (e, href) => {
    e.preventDefault();
    const element = document.querySelector(href);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <footer className="bg-[#0A0A0A] rounded-t-[3.5rem] md:rounded-t-[4rem] border-t border-white/5 pt-16 pb-8 px-6 md:px-12 w-full mt-24">
      <div className="max-w-5xl mx-auto flex flex-col gap-12 text-left">
        
        {/* Top Grid Area */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 md:gap-12">
          {/* Col 1: Brand & Tagline */}
          <div className="md:col-span-2 space-y-4">
            <a href="#" onClick={handleScrollToTop} className="flex items-center gap-2 w-fit">
              <div className="w-8 h-8 rounded-lg bg-[#FF2B2B] flex items-center justify-center">
                <Terminal className="w-4.5 h-4.5 text-[#FFFFFF]" />
              </div>
              <span className="font-heading text-lg font-bold tracking-tight text-[#FFFFFF]">
                Prince<span className="text-[#FF2B2B]">.</span>Jha
              </span>
            </a>
            <p className="font-sans text-xs text-[#A3A3A3] leading-relaxed max-w-sm">
              Designing and building high-performance intelligence tools, mobile experiences, and scalable system backends that endure.
            </p>
          </div>

          {/* Col 2: Navigation column */}
          <div className="space-y-4">
            <h4 className="font-heading text-[10px] font-bold text-white uppercase tracking-wider">Navigation</h4>
            <div className="flex flex-col gap-2.5">
              {[
                { name: "Projects Showcase", href: "#projects" },
                { name: "Capability Stack", href: "#tech-stack" },
                { name: "Operational Flow", href: "#timeline" },
                { name: "Roadmap Focus", href: "#focus" }
              ].map((link) => (
                <a
                  key={link.name}
                  href={link.href}
                  onClick={(e) => handleScrollTo(e, link.href)}
                  className="font-sans text-xs text-[#A3A3A3] hover:text-[#FF2B2B] transition-colors"
                >
                  {link.name}
                </a>
              ))}
            </div>
          </div>

          {/* Col 3: Legal / Meta column */}
          <div className="space-y-4">
            <h4 className="font-heading text-[10px] font-bold text-white uppercase tracking-wider">Contact Gateway</h4>
            <div className="flex flex-col gap-2.5">
              <a href="mailto:princejha.work@gmail.com" className="font-sans text-xs text-[#A3A3A3] hover:text-[#FF2B2B] transition-colors">
                princejha.work@gmail.com
              </a>
              <a href="https://www.linkedin.com/in/prince-jha-7a26a3303" target="_blank" className="font-sans text-xs text-[#A3A3A3] hover:text-[#FF2B2B] transition-colors">
                LinkedIn Profile
              </a>
              <a href="https://github.com/Princejha10" target="_blank" className="font-sans text-xs text-[#A3A3A3] hover:text-[#FF2B2B] transition-colors">
                GitHub Repositories
              </a>
            </div>
          </div>
        </div>

        {/* Bottom Status bar */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-6 pt-8 border-t border-white/5 mt-8 w-full">
          
          {/* Monospace status pulse indicator */}
          <div className="flex items-center gap-2 bg-white/5 border border-white/5 rounded-full px-4 py-1.5 font-mono text-[9px]">
            <span className="w-2 h-2 bg-[#10B981] rounded-full animate-pulse shadow-[0_0_8px_#10B981]" />
            <span className="text-[#10B981] uppercase tracking-wider font-bold">ALL CORE SYSTEMS OPERATIONAL</span>
          </div>

          {/* Back to top button */}
          <button
            onClick={handleScrollToTop}
            className="p-2.5 rounded-full bg-white/5 border border-white/10 hover:bg-white/10 text-white transition-colors group"
          >
            <ArrowUp className="w-4 h-4 group-hover:-translate-y-0.5 transition-transform" />
          </button>
        </div>

        {/* Copyright */}
        <div className="flex flex-col sm:flex-row items-center justify-between text-[9px] font-mono text-white/30 w-full mt-4 gap-2">
          <span>© {new Date().getFullYear()} PRINCE JHA. ALL SPECIFICATIONS RESERVED.</span>
          <span>BUILT WITH NEXT.JS 16 & TAILWIND CSS v4</span>
        </div>

      </div>
    </footer>
  );
}
