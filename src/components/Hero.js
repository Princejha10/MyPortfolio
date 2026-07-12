"use client";
import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import gsap from "gsap";

export default function Hero() {
  const containerRef = useRef(null);
  const introRef = useRef(null);
  const nameRef = useRef(null);
  const rotTextRef = useRef(null);
  const sentenceRef = useRef(null);
  const ctaRef = useRef(null);

  // Rotating text items
  const textItems = [
    "Python Developer",
    "AI Engineer",
    "Full Stack Developer",
    "Problem Solver",
    "Building Real Products",
  ];
  const [textIndex, setTextIndex] = useState(0);

  // Mouse coordinates for background spotlights
  const [mousePos, setMousePos] = useState({ x: 0, y: 0 });
  const [isHovered, setIsHovered] = useState(false);

  useEffect(() => {
    // Text rotation loop
    const interval = setInterval(() => {
      setTextIndex((prev) => (prev + 1) % textItems.length);
    }, 2500);

    // GSAP entrance animations
    const ctx = gsap.context(() => {
      const tl = gsap.timeline({ defaults: { ease: "power3.out" } });

      tl.fromTo(
        introRef.current,
        { y: 15, opacity: 0 },
        { y: 0, opacity: 0.65, duration: 0.8 },
        "+=0.4"
      )
        .fromTo(
          nameRef.current,
          { y: 40, opacity: 0 },
          { y: 0, opacity: 1, duration: 1.2 },
          "-=0.6"
        )
        .fromTo(
          rotTextRef.current,
          { y: 15, opacity: 0 },
          { y: 0, opacity: 1, duration: 0.6 },
          "-=0.7"
        )
        .fromTo(
          sentenceRef.current,
          { y: 15, opacity: 0 },
          { y: 0, opacity: 1, duration: 0.7 },
          "-=0.5"
        )
        .fromTo(
          ctaRef.current,
          { y: 15, opacity: 0 },
          { y: 0, opacity: 1, duration: 0.8 },
          "-=0.5"
        );
    }, containerRef);

    return () => {
      clearInterval(interval);
      ctx.revert();
    };
  }, []);

  const handleMouseMove = (e) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    setMousePos({
      x: e.clientX - rect.left,
      y: e.clientY - rect.top,
    });
  };

  const handleScrollToProjects = (e) => {
    e.preventDefault();
    const element = document.querySelector("#projects");
    if (element) {
      element.scrollIntoView({ behavior: "smooth" });
    }
  };

  return (
    <section
      ref={containerRef}
      id="top"
      onMouseMove={handleMouseMove}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      className="relative min-h-screen w-full flex flex-col items-center justify-center overflow-hidden px-6 md:px-12 pt-32 pb-16 bg-[#050505]"
    >
      {/* Interactive mouse spotlight */}
      <div
        className="absolute inset-0 z-0 pointer-events-none transition-opacity duration-500"
        style={{
          opacity: isHovered ? 1 : 0.4,
          background: `radial-gradient(circle 380px at ${mousePos.x}px ${mousePos.y}px, rgba(255, 43, 43, 0.08) 0%, transparent 100%)`,
        }}
      />

      {/* Tiny floating background particles */}
      <div className="absolute inset-0 z-0 pointer-events-none overflow-hidden">
        {Array.from({ length: 15 }).map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 rounded-full bg-[#FF2B2B]/20"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
            }}
            animate={{
              y: [0, -40, 0],
              opacity: [0.1, 0.4, 0.1],
            }}
            transition={{
              duration: Math.random() * 12 + 10,
              repeat: Infinity,
              ease: "easeInOut",
            }}
          />
        ))}
      </div>

      {/* Hero Content Area (z-20: IN FRONT of the 3D robot, which floats at z-10) */}
      <div className="relative z-20 w-full max-w-none flex flex-col items-center text-center gap-6 mt-48 pointer-events-none">
        
        {/* Name Display - Centered, Spans 80-90% of screen width */}
        <div ref={nameRef} className="relative select-none w-full mb-2 pointer-events-auto px-6 md:px-[8vw] flex flex-col items-start justify-center">
          
          {/* "HI, I'M" - Left aligned above the name block matching the start of P in PRINCE */}
          <span
            ref={introRef}
            className="font-sans text-[15px] sm:text-[17px] font-medium uppercase tracking-[0.4em] text-white/65 mb-4 block text-left pl-1"
            style={{ fontFamily: "'Space Grotesk', sans-serif" }}
          >
            Hi, I'm
          </span>

          <h1 className="font-heading text-[11.5vw] font-black tracking-tighter uppercase leading-[0.8] flex flex-row items-center justify-start gap-x-[2.5vw] w-full text-left">
            <span className="text-white">PRINCE</span>
            <span className="bg-gradient-to-r from-[#FF2E2E] to-[#FF4A4A] bg-clip-text text-transparent">JHA</span>
          </h1>
        </div>

        {/* Rotating Text Container */}
        <div ref={rotTextRef} className="h-8 md:h-10 overflow-hidden relative flex items-center justify-center pointer-events-auto">
          <AnimatePresence mode="wait">
            <motion.span
              key={textIndex}
              initial={{ y: 15, opacity: 0 }}
              animate={{ y: 0, opacity: 1 }}
              exit={{ y: -15, opacity: 0 }}
              transition={{ duration: 0.35, ease: "easeOut" }}
              className="font-mono text-xs md:text-lg font-bold uppercase tracking-widest text-[#FF2B2B] block"
            >
              {textItems[textIndex]}
            </motion.span>
          </AnimatePresence>
        </div>

        {/* Subtext description */}
        <div ref={sentenceRef} className="max-w-[650px] pointer-events-auto">
          <p className="font-sans text-sm md:text-base text-[#A3A3A3] leading-relaxed">
            Building AI-powered products that solve real-world problems.
          </p>
        </div>

        {/* CTA Buttons (z-30: fully interactive) */}
        <div ref={ctaRef} className="flex flex-col sm:flex-row items-center justify-center gap-4 w-full mt-4 pointer-events-auto z-30">
          <a
            href="#projects"
            onClick={handleScrollToProjects}
            className="magnetic-btn group bg-[#FF2B2B] hover:bg-[#E11D48] text-white text-xs font-heading font-medium tracking-widest uppercase py-3.5 px-8 rounded-full flex items-center justify-center gap-2 shadow-[0_0_20px_rgba(255,43,43,0.18)] w-full sm:w-auto transition-all hover:scale-[1.04]"
          >
            <span className="flex items-center gap-1.5">
              View Projects <span className="group-hover:translate-y-0.5 transition-transform">↓</span>
            </span>
          </a>

          <a
            href="/resume.pdf"
            target="_blank"
            rel="noopener noreferrer"
            className="magnetic-btn group border border-white/10 hover:border-[#FF2B2B] bg-transparent hover:shadow-[0_0_20px_rgba(255,43,43,0.15)] text-white text-xs font-heading font-medium tracking-widest uppercase py-3.5 px-8 rounded-full flex items-center justify-center gap-2 w-full sm:w-auto transition-all"
          >
            <span>Resume</span>
          </a>
        </div>

      </div>

      {/* Mouse Scroll Indicator */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 z-30 hidden md:flex flex-col items-center gap-1.5 text-[#A3A3A3]">
        <motion.div
          animate={{ y: [0, 4, 0] }}
          transition={{ duration: 1.5, repeat: Infinity, ease: "easeInOut" }}
          className="w-4 h-7 rounded-full border border-white/15 flex justify-center pt-1.5"
        >
          <div className="w-1 h-1.5 rounded-full bg-[#FF2B2B]" />
        </motion.div>
      </div>
    </section>
  );
}
