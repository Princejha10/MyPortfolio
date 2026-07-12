"use client";
import { useEffect, useRef } from "react";

export default function Features() {
  const canvasRef = useRef(null);
  const containerRef = useRef(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId;
    let width = (canvas.width = containerRef.current.clientWidth);
    let height = (canvas.height = 360);

    // Mouse coordinates (with spring logic)
    const mouse = { x: width / 2, y: height / 2, active: false };
    const spring = { x: width / 2, y: height / 2 };
    const ease = 0.08;

    // Particles list
    const particles = [];
    const particleCount = Math.min(40, Math.floor(width / 30));

    class Particle {
      constructor() {
        this.x = Math.random() * width;
        this.y = Math.random() * height;
        this.size = Math.random() * 2 + 1;
        this.vx = (Math.random() - 0.5) * 0.3;
        this.vy = (Math.random() - 0.5) * 0.3;
        this.alpha = Math.random() * 0.5 + 0.1;
      }

      update() {
        this.x += this.vx;
        this.y += this.vy;

        // Boundaries
        if (this.x < 0 || this.x > width) this.vx *= -1;
        if (this.y < 0 || this.y > height) this.vy *= -1;
      }

      draw() {
        ctx.save();
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255, 43, 43, ${this.alpha})`;
        ctx.fill();
        ctx.restore();
      }
    }

    // Initialize particles
    for (let i = 0; i < particleCount; i++) {
      particles.push(new Particle());
    }

    const handleResize = () => {
      if (!containerRef.current) return;
      width = canvas.width = containerRef.current.clientWidth;
      height = canvas.height = 360;
    };

    window.addEventListener("resize", handleResize);

    const handleMouseMove = (e) => {
      const rect = canvas.getBoundingClientRect();
      mouse.x = e.clientX - rect.left;
      mouse.y = e.clientY - rect.top;
      mouse.active = true;
    };

    const handleMouseLeave = () => {
      mouse.active = false;
    };

    canvas.addEventListener("mousemove", handleMouseMove);
    canvas.addEventListener("mouseleave", handleMouseLeave);

    // Core Animation loop (60 FPS)
    const render = () => {
      ctx.clearRect(0, 0, width, height);

      // 1. Spring physics lag calculation
      if (mouse.active) {
        spring.x += (mouse.x - spring.x) * ease;
        spring.y += (mouse.y - spring.y) * ease;
      } else {
        // Return to center slowly
        spring.x += (width / 2 - spring.x) * 0.03;
        spring.y += (height / 2 - spring.y) * 0.03;
      }

      // 2. Draw red background spotlight glow
      ctx.save();
      const gradient = ctx.createRadialGradient(
        spring.x,
        spring.y,
        0,
        spring.x,
        spring.y,
        180
      );
      gradient.addColorStop(0, "rgba(255, 43, 43, 0.12)");
      gradient.addColorStop(0.5, "rgba(225, 29, 72, 0.04)");
      gradient.addColorStop(1, "rgba(5, 5, 5, 0)");
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, width, height);
      ctx.restore();

      // 3. Draw coordinates helper lines
      ctx.strokeStyle = "rgba(255, 255, 255, 0.02)";
      ctx.lineWidth = 0.5;
      const step = 30;
      for (let x = 0; x < width; x += step) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }
      for (let y = 0; y < height; y += step) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
        ctx.stroke();
      }

      // 4. Update and draw particles
      particles.forEach((p) => {
        p.update();
        p.draw();

        // Connect lines from particles to cursor
        const dx = p.x - spring.x;
        const dy = p.y - spring.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 120) {
          ctx.save();
          ctx.beginPath();
          ctx.moveTo(p.x, p.y);
          ctx.lineTo(spring.x, spring.y);
          ctx.strokeStyle = `rgba(255, 43, 43, ${0.15 * (1 - dist / 120)})`;
          ctx.lineWidth = 0.5;
          ctx.stroke();
          ctx.restore();
        }
      });

      // 5. Draw cursor indicator ring
      ctx.save();
      ctx.beginPath();
      ctx.arc(spring.x, spring.y, 8, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(255, 43, 43, 0.6)";
      ctx.lineWidth = 1;
      ctx.stroke();

      ctx.beginPath();
      ctx.arc(spring.x, spring.y, 2, 0, Math.PI * 2);
      ctx.fillStyle = "#FF2B2B";
      ctx.fill();
      ctx.restore();

      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener("resize", handleResize);
      if (canvas) {
        canvas.removeEventListener("mousemove", handleMouseMove);
        canvas.removeEventListener("mouseleave", handleMouseLeave);
      }
    };
  }, []);

  return (
    <section className="py-16 px-6 md:px-12 max-w-7xl mx-auto w-full relative select-none animate-fadeIn">
      <div ref={containerRef} className="relative w-full rounded-[2rem] border border-white/5 bg-[#0A0A0A] overflow-hidden h-[360px] shadow-2xl">
        <canvas ref={canvasRef} className="absolute inset-0 w-full h-full cursor-none" />
      </div>
    </section>
  );
}
