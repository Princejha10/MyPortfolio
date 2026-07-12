"use client";
import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Menu, X } from "lucide-react";

export default function Navbar() {
  const [activeSection, setActiveSection] = useState("home");
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      // Track active section for indicator matching
      const sections = ["top", "about", "projects", "experience", "github", "contact"];
      for (const section of sections) {
        const el = document.getElementById(section === "top" ? "top" : section);
        if (el) {
          const rect = el.getBoundingClientRect();
          if (rect.top <= 160 && rect.bottom >= 160) {
            setActiveSection(section === "top" ? "home" : section);
            break;
          }
        }
      }
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const navLinks = [
    { name: "Home", href: "#top", id: "home" },
    { name: "About", href: "#about", id: "about" },
    { name: "Projects", href: "#projects", id: "projects" },
    { name: "Experience", href: "#experience", id: "experience" },
    { name: "GitHub", href: "#github", id: "github" },
    { name: "Contact", href: "#contact", id: "contact" },
  ];

  const handleScrollTo = (e, href, id) => {
    e.preventDefault();
    setMobileMenuOpen(false);
    setActiveSection(id);
    const targetId = href.startsWith("#") ? href.slice(1) : href;
    const element = document.getElementById(targetId);
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <>
      <nav
        className="nav-pill-container fixed z-55 rounded-full border border-white/5 py-1 px-1.5 shadow-2xl flex items-center justify-between"
        style={{
          left: "50%",
          transform: "translate3d(-50%, 0, 0)",
          top: "20px",
          width: "92%",
          maxWidth: "720px",
          height: "56px",
          backgroundColor: "rgba(10, 10, 10, 0.45)",
          backdropFilter: "blur(12px)",
          pointerEvents: "auto"
        }}
      >
        {/* Desktop Layout */}
        <div className="hidden md:flex items-center justify-between w-full h-full">
          
          {/* Navigation Links (Hugging Left) */}
          <div className="flex items-center gap-1">
            {navLinks.map((link) => {
              const isActive = activeSection === link.id;
              return (
                <a
                  key={link.name}
                  href={link.href}
                  onClick={(e) => handleScrollTo(e, link.href, link.id)}
                  className={`font-sans font-bold uppercase tracking-widest relative px-3 py-2 rounded-full transition-all duration-300 hover:-translate-y-[1px] text-[9px] ${
                    isActive ? "text-white" : "text-[#A3A3A3] hover:text-white hover:drop-shadow-[0_0_8px_rgba(255,255,255,0.3)]"
                  }`}
                  style={{ fontFamily: "'Space Grotesk', sans-serif" }}
                >
                  {/* Thin glowing pill behind active tab */}
                  {isActive && (
                    <motion.span
                      layoutId="navPillHighlight"
                      className="absolute inset-0 bg-[#FF2B2B]/10 border border-[#FF2B2B]/20 rounded-full -z-10"
                      transition={{ type: "spring", stiffness: 380, damping: 30 }}
                    />
                  )}
                  <span>{link.name}</span>
                </a>
              );
            })}
          </div>

          {/* Attached Red Resume Button (Hugging Right inside same container) */}
          <div className="flex items-center">
            <a
              href="/resume.pdf"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-[#FF2E2E] hover:bg-[#FF4A4A] text-white font-sans font-bold tracking-widest uppercase rounded-full transition-all duration-300 hover:scale-[1.05] text-[9px] py-2 px-5 shrink-0 flex items-center justify-center h-[38px] shadow-[0_4px_12px_rgba(255,46,46,0.18)]"
              style={{ fontFamily: "'Space Grotesk', sans-serif" }}
            >
              Resume →
            </a>
          </div>

        </div>

        {/* Mobile / Tablet Header controls */}
        <div className="md:hidden flex items-center justify-between w-full h-full px-2">
          <a
            href="#top"
            className="font-heading text-xs font-bold text-white uppercase"
            onClick={(e) => handleScrollTo(e, "#top", "home")}
          >
            Prince<span className="text-[#FF2B2B]">.</span>
          </a>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="p-1.5 rounded-full bg-white/5 border border-white/5 text-white hover:bg-white/10 transition-colors"
          >
            {mobileMenuOpen ? <X className="w-4 h-4" /> : <Menu className="w-4 h-4" />}
          </button>
        </div>
      </nav>

      {/* Mobile Drawer Menu */}
      <AnimatePresence>
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }}
            className="fixed inset-0 z-45 bg-[#050505]/98 backdrop-blur-lg md:hidden flex flex-col justify-center px-10"
          >
            <div className="flex flex-col gap-6 text-left">
              {navLinks.map((link) => (
                <a
                  key={link.name}
                  href={link.href}
                  onClick={(e) => handleScrollTo(e, link.href, link.id)}
                  className={`font-heading text-2xl font-bold tracking-tight uppercase ${
                    activeSection === link.id ? "text-[#FF2B2B]" : "text-white hover:text-[#FF2B2B]"
                  }`}
                >
                  {link.name}
                </a>
              ))}
              <div className="h-[1px] bg-white/5 my-4" />
              <a
                href="/resume.pdf"
                target="_blank"
                rel="noopener noreferrer"
                onClick={() => setMobileMenuOpen(false)}
                className="bg-[#FF2B2B] text-white text-center py-3.5 rounded-full font-heading text-sm font-semibold uppercase tracking-widest"
              >
                Resume
              </a>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
