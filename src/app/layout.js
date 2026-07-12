import { Space_Grotesk, Inter, DM_Serif_Display, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space-grotesk",
  subsets: ["latin"],
});

const inter = Inter({
  variable: "--font-inter",
  subsets: ["latin"],
});

const dmSerif = DM_Serif_Display({
  variable: "--font-dm-serif",
  weight: "400",
  style: "italic",
  subsets: ["latin"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains-mono",
  subsets: ["latin"],
});

export const viewport = {
  width: "device-width",
  initialScale: 1,
};

export const metadata = {
  title: "Prince Jha | AI Engineer, Flutter & Full-Stack Developer",
  description: "Prince Jha builds high-performance, AI-powered software and Flutter apps that solve real-world problems. Discover his projects, tech stack, and experience.",
  keywords: ["AI Engineer", "Flutter Developer", "Full Stack Developer", "Prince Jha", "FinSense", "Agentic AI", "Portfolio"],
  authors: [{ name: "Prince Jha" }],
};

export default function RootLayout({ children }) {
  return (
    <html
      lang="en"
      className={`${spaceGrotesk.variable} ${inter.variable} ${dmSerif.variable} ${jetbrainsMono.variable} h-full antialiased`}
    >
      <body className="min-h-full bg-[#0B0F19] text-[#FFFFFF] font-sans selection:bg-[#3B82F6]/30 selection:text-[#FFFFFF]">
        {children}
      </body>
    </html>
  );
}
