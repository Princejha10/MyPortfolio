"use client";
import { useEffect, useRef, useState } from "react";
import { Send, Bot, User, Sparkles, X } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

export default function Chatbot({ isOpen, onClose }) {
  const [messages, setMessages] = useState([
    {
      sender: "bot",
      text: "Hi Prince 👋\n\nHow can I help you today?",
      timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
    }
  ]);
  const [inputText, setInputText] = useState("");
  const [isTyping, setIsTyping] = useState(false);
  const chatEndRef = useRef(null);

  useEffect(() => {
    if (chatEndRef.current) {
      chatEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages, isTyping]);

  const quickPrompts = [
    { label: "About Me", query: "Tell me about Prince Jha." },
    { label: "My Projects", query: "What projects have you built?" },
    { label: "Skills", query: "What are your core technical skills?" },
    { label: "Resume", query: "How can I download or view your resume?" },
    { label: "Contact", query: "How can I get in touch with you?" }
  ];

  const getAIResponse = (query) => {
    const q = query.toLowerCase();
    if (q.includes("about") || q.includes("yourself") || q.includes("who is")) {
      return "Prince Jha is an AI Engineer, Python Developer, and Full-Stack Architect. He builds high-performance, intelligent digital products that solve real-world problems.";
    }
    if (q.includes("project") || q.includes("built") || q.includes("work")) {
      return "Prince has built projects like FinSense (a secure offline SMS-parsing financial monitor built in Flutter) and multiple database scrapers in Python.";
    }
    if (q.includes("skill") || q.includes("technical") || q.includes("stack")) {
      return "Prince's stack centers on Python backend pipelines, Flutter mobile engineering, Next.js/React layout grids, SQLite databases, and prompt systems.";
    }
    if (q.includes("resume") || q.includes("cv")) {
      return "You can download his resume directly by clicking the 'Resume' button in the navigation bar, or click this link: /resume.pdf.";
    }
    if (q.includes("contact") || q.includes("touch") || q.includes("reach")) {
      return "Reach Prince Jha via email at princejha.work@gmail.com, or fill out the Contact form at the bottom of the page.";
    }
    return "Thank you for asking! Prince is specialized in AI engineering, Python backend infrastructure, and Flutter app development. Let me know if you would like info on any specific area.";
  };

  const handleSendMessage = (textToSend) => {
    if (!textToSend.trim()) return;

    // Add user message
    const userMsg = {
      sender: "user",
      text: textToSend,
      timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
    };
    setMessages((prev) => [...prev, userMsg]);
    setInputText("");
    setIsTyping(true);

    // Simulate thinking state
    setTimeout(() => {
      setIsTyping(false);
      const botMsg = {
        sender: "bot",
        text: getAIResponse(textToSend),
        timestamp: new Date().toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })
      };
      setMessages((prev) => [...prev, botMsg]);
    }, 1000);
  };

  return (
    <div className="fixed bottom-6 right-6 z-40">
      {/* Chat window */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            className="absolute bottom-0 right-0 w-[320px] sm:w-[380px] h-[480px] rounded-[2rem] bg-[#0A0A0A]/95 backdrop-blur-xl border border-white/5 shadow-[0_20px_50px_rgba(0,0,0,0.6)] flex flex-col overflow-hidden"
          >
            {/* Window Header */}
            <div className="bg-[#111111] px-6 py-4 flex items-center justify-between border-b border-white/5">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-[#FF2B2B]/10 flex items-center justify-center border border-[#FF2B2B]/20">
                  <span className="text-xs">🤖</span>
                </div>
                <div className="text-left">
                  <h4 className="text-xs font-bold font-heading text-white uppercase tracking-wider">Prince AI Assistant</h4>
                  <span className="text-[8px] font-mono text-[#10B981] flex items-center gap-1">
                    <span className="w-1.5 h-1.5 bg-[#10B981] rounded-full animate-pulse" />
                    ONLINE
                  </span>
                </div>
              </div>
              
              <div className="flex items-center gap-2">
                <Sparkles className="w-3.5 h-3.5 text-[#FF2B2B]" />
                <button
                  onClick={onClose}
                  className="p-1 rounded-lg hover:bg-white/5 text-[#A3A3A3] hover:text-white transition-colors cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Chat Messages */}
            <div className="flex-1 overflow-y-auto p-5 space-y-4 scrollbar-none">
              {messages.map((msg, idx) => (
                <div
                  key={idx}
                  className={`flex gap-3 max-w-[85%] ${
                    msg.sender === "user" ? "ml-auto flex-row-reverse" : "mr-auto"
                  }`}
                >
                  <div
                    className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 border ${
                      msg.sender === "user"
                        ? "bg-white/5 border-white/5 text-[#A3A3A3]"
                        : "bg-[#FF2B2B]/5 border-[#FF2B2B]/10 text-[#FF2B2B]"
                    }`}
                  >
                    {msg.sender === "user" ? <User className="w-3.5 h-3.5" /> : <Bot className="w-3.5 h-3.5" />}
                  </div>

                  <div className="flex flex-col gap-1 text-left">
                    <div
                      className={`text-xs p-3.5 rounded-2xl leading-relaxed whitespace-pre-line ${
                        msg.sender === "user"
                          ? "bg-[#FF2B2B] text-white rounded-tr-none"
                          : "bg-white/5 text-[#A3A3A3] rounded-tl-none border border-white/5"
                      }`}
                    >
                      {msg.text}
                    </div>
                    <span className="text-[8px] font-mono text-white/30 self-end px-1">{msg.timestamp}</span>
                  </div>
                </div>
              ))}

              {/* Typing loader */}
              {isTyping && (
                <div className="flex gap-3 mr-auto max-w-[85%]">
                  <div className="w-7 h-7 rounded-lg bg-[#FF2B2B]/5 border border-[#FF2B2B]/10 text-[#FF2B2B] flex items-center justify-center shrink-0">
                    <Bot className="w-3.5 h-3.5 animate-pulse" />
                  </div>
                  <div className="bg-white/5 border border-white/5 text-xs p-3.5 rounded-2xl rounded-tl-none flex items-center gap-1">
                    <span className="w-1.5 h-1.5 bg-[#A3A3A3] rounded-full animate-bounce" style={{ animationDelay: "0ms" }} />
                    <span className="w-1.5 h-1.5 bg-[#A3A3A3] rounded-full animate-bounce" style={{ animationDelay: "150ms" }} />
                    <span className="w-1.5 h-1.5 bg-[#A3A3A3] rounded-full animate-bounce" style={{ animationDelay: "300ms" }} />
                  </div>
                </div>
              )}
              <div ref={chatEndRef} />
            </div>

            {/* Quick Suggestions (About, Projects, Skills, Resume, Contact) */}
            <div className="px-5 pb-3 pt-1.5 flex gap-1.5 overflow-x-auto scrollbar-none border-t border-white/5">
              {quickPrompts.map((p) => (
                <button
                  key={p.label}
                  onClick={() => handleSendMessage(p.query)}
                  className="bg-white/5 border border-white/5 hover:border-white/10 rounded-lg px-2.5 py-1.5 text-[8px] font-heading font-bold tracking-wide uppercase text-white/80 whitespace-nowrap transition-colors cursor-pointer"
                >
                  {p.label}
                </button>
              ))}
            </div>

            {/* Input form */}
            <div className="p-4 bg-[#111111] border-t border-white/5">
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  handleSendMessage(inputText);
                }}
                className="flex items-center gap-2"
              >
                <input
                  type="text"
                  value={inputText}
                  onChange={(e) => setInputText(e.target.value)}
                  placeholder="Ask a question..."
                  className="flex-1 bg-[#050505] border border-white/5 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-[#FF2B2B] transition-colors"
                />
                <button
                  type="submit"
                  className="p-2.5 rounded-xl bg-[#FF2B2B] text-white hover:bg-[#FF2B2B]/90 transition-colors"
                >
                  <Send className="w-4 h-4" />
                </button>
              </form>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
