"use client";
import { useState, useEffect, useRef } from "react";
import dynamic from "next/dynamic";
import Loader from "@/components/Loader";
import Navbar from "@/components/Navbar";
import Hero from "@/components/Hero";
import Features from "@/components/Features";
import Philosophy from "@/components/Philosophy";
import Protocol from "@/components/Protocol";
import TechStack from "@/components/TechStack";
import Projects from "@/components/Projects";
import ExperienceEducation from "@/components/ExperienceEducation";
import GithubActivity from "@/components/GithubActivity";
import CurrentFocus from "@/components/CurrentFocus";
import Contact from "@/components/Contact";
import Footer from "@/components/Footer";
import Chatbot from "@/components/Chatbot";
import CommandPalette from "@/components/CommandPalette";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";

// Register GSAP ScrollTrigger only on Client side
if (typeof window !== "undefined") {
  gsap.registerPlugin(ScrollTrigger);
}

// Import Three.js Canvas dynamically to prevent Next SSR context crashes
const RobotCanvas = dynamic(() => import("@/components/RobotCanvas"), { ssr: false });

export default function Home() {
  const [isLoading, setIsLoading] = useState(true);
  const [commandPaletteOpen, setCommandPaletteOpen] = useState(false);
  const [chatOpen, setChatOpen] = useState(false);
  const [scrollProgress, setScrollProgress] = useState(0);
  
  // Click trackers to pass to Three.js canvas without re-mounts
  const [robotClickCount, setRobotClickCount] = useState(0);
  
  // Ref to hold the GSAP ScrollTrigger timeline
  const scrollTimelineRef = useRef(null);

  useEffect(() => {
    if (isLoading) return;
    const handleScroll = () => {
      setScrollProgress(window.scrollY / 450);
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, [isLoading]);

  // 1. Initialize GSAP ScrollTrigger animations on mount
  useEffect(() => {
    if (isLoading) return;

    // A. Baseline setup for Robot Wrapper — positioned on the RIGHT side
    gsap.set(".robot-assistant-wrapper", {
      left: "75%",
      top: "22vh",
      scale: 1.15,
      xPercent: -50,
      yPercent: 0,
      y: 0,
      zIndex: 10
    });

    // B. Robot Scroll Path Timeline (Hero -> 25% -> 50% -> 100%)
    const robotTl = gsap.timeline({
      scrollTrigger: {
        trigger: "#top",
        start: "top top",
        end: "bottom top",
        scrub: 1.4, // smooth spring-scrub lag
      }
    });

    robotTl
      .to(".robot-assistant-wrapper", {
        // 25% Scroll: Slowly moves upward (still on right side)
        left: "75%",
        top: "10vh",
        scale: 1.05,
        xPercent: -50,
        zIndex: 10,
        duration: 0.25,
        ease: "power1.inOut"
      })
      .to(".robot-assistant-wrapper", {
        // 50% Scroll: Moves toward the navbar (lifts z-index in front)
        left: "80%",
        top: "60px",
        scale: 0.88,
        xPercent: -50,
        zIndex: 50,
        duration: 0.25,
        ease: "power2.inOut"
      })
      .to(".robot-assistant-wrapper", {
        // 100% Scroll: Floating assistant docked beside the navbar (clamped safely inside screen viewport)
        left: "calc(100% - 24px)",
        top: "24px",
        scale: 0.72,
        xPercent: -100,
        zIndex: 50,
        duration: 0.5,
        ease: "power3.out"
      });

    scrollTimelineRef.current = robotTl;

    // C. Responsive Redesigned Compact Navbar Animations using GSAP MatchMedia
    const mm = gsap.matchMedia();

    // Desktop: Animates from Top-Right (State 1: 520px width) to Top-Center (State 2: 560px width)
    mm.add("(min-width: 1024px)", () => {
      const isInitiallyScrolled = window.scrollY > window.innerHeight - 120;

      gsap.set(".nav-pill-container", {
        left: "50%",
        top: 20,
        xPercent: -50,
        x: isInitiallyScrolled ? "0px" : "calc(50vw - 300px)",
        y: isInitiallyScrolled ? 0 : 20, // 20px offset + 20px top = 40px top margin
        width: isInitiallyScrolled ? "560px" : "520px",
        height: "56px",
        backgroundColor: isInitiallyScrolled ? "rgba(10, 10, 10, 0.75)" : "rgba(10, 10, 10, 0.45)",
        backdropFilter: isInitiallyScrolled ? "blur(18px)" : "blur(12px)",
        border: "1px solid rgba(255,255,255,0.06)",
        opacity: 1,
        zIndex: 9999
      });

      const navTrigger = ScrollTrigger.create({
        trigger: "#top",
        start: "bottom-=120 top",
        onToggle: (self) => {
          if (self.isActive) {
            // State 2 (Scrolled Center)
            gsap.to(".nav-pill-container", {
              x: "0px",
              y: 0,
              width: "560px",
              backgroundColor: "rgba(10, 10, 10, 0.75)",
              backdropFilter: "blur(18px)",
              duration: 0.7,
              ease: "power3.out"
            });
          } else {
            // State 1 (Hero Right)
            gsap.to(".nav-pill-container", {
              x: "calc(50vw - 300px)",
              y: 20,
              width: "520px",
              backgroundColor: "rgba(10, 10, 10, 0.45)",
              backdropFilter: "blur(12px)",
              duration: 0.7,
              ease: "power3.out"
            });
          }
        }
      });

      return () => {
        navTrigger.kill();
      };
    });

    // Tablet / Mobile: Always centered top of screen
    mm.add("(max-width: 1023px)", () => {
      gsap.set(".nav-pill-container", {
        left: "50%",
        top: 20,
        xPercent: -50,
        x: "0px",
        y: 0,
        width: "92%",
        maxWidth: 720,
        height: "56px",
        backgroundColor: "rgba(10, 10, 10, 0.75)",
        backdropFilter: "blur(16px)",
        border: "1px solid rgba(255,255,255,0.06)",
        opacity: 1,
        zIndex: 9999
      });
    });

    return () => {
      if (robotTl.scrollTrigger) robotTl.scrollTrigger.kill();
      mm.revert();
    };
  }, [isLoading]);

  // 2. Animate between ScrollTrigger and Chat positions on Chat Open/Close
  useEffect(() => {
    const tl = scrollTimelineRef.current;
    if (!tl || !tl.scrollTrigger) return;

    if (chatOpen) {
      // Disable ScrollTrigger so it doesn't fight our chat coordinates
      tl.scrollTrigger.disable(false);

      // Slide robot to float right above the Chat Panel, fully clamped inside viewport
      gsap.to(".robot-assistant-wrapper", {
        left: "calc(100% - 24px)",
        top: "calc(100vh - 590px)",
        scale: 0.72,
        xPercent: -100,
        y: 0,
        zIndex: 50,
        duration: 0.6,
        ease: "power3.out"
      });
    } else {
      // Re-enable ScrollTrigger
      tl.scrollTrigger.enable();
      
      // Update ScrollTrigger scroll progress and let scrub animate back
      tl.scrollTrigger.scroll(window.scrollY);
      tl.scrollTrigger.update();
    }
  }, [chatOpen]);

  // 3. Click handler for robot click triggers
  const handleRobotClick = () => {
    if (chatOpen) {
      setChatOpen(false); // Close chat if already open
    } else {
      setRobotClickCount((prev) => prev + 1);

      // Play a quick vertical bounce animation on the wrapper container using GSAP
      gsap.timeline()
        .to(".robot-assistant-wrapper", { y: -32, duration: 0.35, ease: "power2.out" })
        .to(".robot-assistant-wrapper", { y: 10, duration: 0.3, ease: "power2.in" })
        .to(".robot-assistant-wrapper", { y: 0, duration: 0.25, ease: "power2.out" });
    }
  };

  const handleRobotInteractionComplete = () => {
    setChatOpen(true);
  };

  return (
    <>
      {isLoading ? (
        <Loader onComplete={() => setIsLoading(false)} />
      ) : (
        <div className="relative min-h-screen bg-[#050505] text-white flex flex-col items-center">
          {/* Global SVG Noise Overlay */}
          <div className="noise-overlay" />

          {/* Core Shell Components */}
          <Navbar onOpenCommandPalette={() => setCommandPaletteOpen(true)} />
          
          {/* Single Permanent Mounted 3D Robot Assistant (z-10: Behind Typography, clickable) */}
          <div
            onClick={handleRobotClick}
            className="robot-assistant-wrapper fixed z-10 cursor-pointer pointer-events-auto"
            style={{
              width: 320,
              height: 320,
              willChange: "transform",
              transformStyle: "preserve-3d"
            }}
          >
            <RobotCanvas
              isScrolled={scrollProgress > 0.3}
              chatOpen={chatOpen}
              clickTrigger={robotClickCount}
              onInteractionComplete={handleRobotInteractionComplete}
            />
          </div>

          <main className="w-full flex-1">
            {/* 1. Hero */}
            <Hero />
            
            {/* 2. Interactive Cursor follower grid */}
            <Features />
            
            {/* 3. About Me */}
            <Philosophy />

            {/* 4. Journey Timeline flow */}
            <Protocol />
            
            {/* 5. Projects Showcase */}
            <Projects />
            
            {/* 6. Technical Stack */}
            <TechStack />
            
            {/* 7. Career Milestones & Education & Certs */}
            <ExperienceEducation />
            
            {/* 8. Dynamic GitHub sync activity stats */}
            <GithubActivity />

            {/* 9. Active study roadmap */}
            <CurrentFocus />
            
            {/* 10. Connection Gateway */}
            <Contact />
          </main>

          {/* Footer */}
          <Footer />

          {/* Floating Premium AI Chatbot (Linked directly to 3D Assistant interactions) */}
          <Chatbot isOpen={chatOpen} onClose={() => setChatOpen(false)} />

          {/* Recruiter Command Palette (Ctrl+K) */}
          <CommandPalette
            isOpen={commandPaletteOpen}
            onClose={(open) => {
              if (open === true) setCommandPaletteOpen(true);
              else setCommandPaletteOpen(false);
            }}
          />
        </div>
      )}
    </>
  );
}
