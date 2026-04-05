#include "CppCommponents/File.h"
#include "CppCommponents/Folder.h"

#include "CppCommponents/Random.h"

#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <iostream>
#include <stdexcept>
#include <assert.h>

#include "ShaderRuntime.h"

std::string f_embeded_GLSL_source_base_glsl();
std::string f_embeded_GLSL_source_vertex_shader_exploring_0000();
std::string f_embeded_GLSL_source_fragment_shader();

namespace GenerateShaders_
{
	struct Writer
	{
		// Reserve a few lines up front if you like:
		Writer(size_t reserveCount = 0)
		{
			if (reserveCount > 0)
				lines.reserve(reserveCount);
		}

		// Append a single line (without trailing newline—LineCollector will add it for you).
		void appendLine(const std::string& line)
		{
			lines.push_back(line);
		}

		// Given a path, read every line (using std::getline) and append it.
		// If the file can't be opened, throw an exception.
		void appendLinesFromFile(const std::string& filepath)
		{
			std::ifstream inFile(filepath);
			if (!inFile.is_open())
				throw std::runtime_error("Failed to open file for reading: " + filepath);

			std::string buffer;
			while (std::getline(inFile, buffer)) {
				lines.push_back(buffer);
			}
			// Optional: if you want to preserve the final newline even if the file didn't have one,
			// you could do: if (!buffer.empty()) lines.push_back(""); 
			// but typically getline reads up to '\n' and discards it, so pushing each line is enough.
		}

		// Join all stored lines into a single std::string with '\n' after each.
		// (If you want a trailing newline at the very end, this function already does it.)
		std::string join() const
		{
			std::ostringstream oss;
			for (const auto& L : lines) {
				oss << L << '\n';
			}
			return oss.str();
		}

		// Write everything out in one go (overwriting any existing file).
		// Internally calls your File::writeFile_OverrideIfExistAlready.
		void writeToFileOverride(const std::string& outPath) const
		{
			File::writeFile_OverrideIfExistAlready(outPath, join());
		}

		// Perform an in place find replace across every stored line.
	// This replaces **all** (non overlapping) occurrences of 'search' with 'replacement'.
		void replaceAll(const std::string& search, const std::string& replacement)
		{
			if (search.empty())
				return; // Avoid infinite loop if someone passes an empty search string.

			for (auto& line : lines) {
				size_t pos = 0;
				// Keep replacing until no more occurrences in this line
				while ((pos = line.find(search, pos)) != std::string::npos) {
					line.replace(pos, search.length(), replacement);
					pos += replacement.length();
				}
			}
		}
	private:
		std::vector<std::string> lines;
	};

	struct Line
	{
		void add(const std::string& line)
		{
			elements.push_back(line);
		}

		void clear()
		{
			elements.clear();
		}

		std::string join() const
		{
			std::ostringstream oss;
			for (const auto& L : elements) {
				oss << L;
			}
			return oss.str();
		}

		std::vector<std::string> elements;
	};




	void generate_shader_0(Writer& w_definitons, Writer& w_expression)
	{
		// SDF

		struct WaveSphere
		{
			static void generate_definiton(Writer& w_definitons)
			{
				w_definitons.appendLine("float sdWavySphere(");
				w_definitons.appendLine("    in vec3 p,");
				w_definitons.appendLine("    in float baseRad,");
				w_definitons.appendLine("    in float amp1, in float freq1, in float speed1, in float phase1,");
				w_definitons.appendLine("    in float amp2, in float freq2, in float speed2, in float phase2,");
				w_definitons.appendLine("    in float amp3, in float freq3, in float speed3, in float phase3");
				w_definitons.appendLine(") {");
				w_definitons.appendLine("    // Compute the raw radius");
				w_definitons.appendLine("    float r = length(p);");
				w_definitons.appendLine("    if (r <= 0.0001) {");
				w_definitons.appendLine("        // Avoid division by zero when normalizing");
				w_definitons.appendLine("        return r - baseRad;");
				w_definitons.appendLine("    }");
				w_definitons.appendLine("");
				w_definitons.appendLine("    // Normalize p to get spherical coordinates");
				w_definitons.appendLine("    vec3 n = p / r;");
				w_definitons.appendLine("    float theta = acos(clamp(n.y, -1.0, 1.0));");
				w_definitons.appendLine("    float phi = atan(n.z, n.x);");
				w_definitons.appendLine("");
				w_definitons.appendLine("    // Layer 1: variation in  (latitude)");
				w_definitons.appendLine("    float w1 = amp1 * sin(freq1 * theta + speed1 * time + phase1);");
				w_definitons.appendLine("");
				w_definitons.appendLine("    // Layer 2: variation in  (longitude)");
				w_definitons.appendLine("    float w2 = amp2 * sin(freq2 * phi + speed2 * time + phase2);");
				w_definitons.appendLine("");
				w_definitons.appendLine("    // Layer 3: variation along the radial direction itself");
				w_definitons.appendLine("    float w3 = amp3 * sin(freq3 * r + speed3 * time + phase3);");
				w_definitons.appendLine("");
				w_definitons.appendLine("    // Total radial displacement from all three wave layers");
				w_definitons.appendLine("    float totalWave = w1 + w2 + w3;");
				w_definitons.appendLine("");
				w_definitons.appendLine("    // The “effective” radius at this direction = baseRad + totalWave");
				w_definitons.appendLine("    float effectiveRadius = baseRad + totalWave;");
				w_definitons.appendLine("");
				w_definitons.appendLine("    // Return signed distance: (distance to origin) – (effective radius)");
				w_definitons.appendLine("    return r - effectiveRadius;");
				w_definitons.appendLine("}");
			}

			/*
			int function_index = 0;
			float base_radious = 0.2;

			float amplitude_1 = 0.02;
			float frequeny_1  = 10.0;
			float speed_1     = 1.0;
			float phase_1     = 0.01;

			float amplitude_2 = 0.02;
			float frequeny_2 = 10.0;
			float speed_2 = 1.0;
			float phase_2 = 0.01;

			float amplitude_3 = 0.02;
			float frequeny_3 = 10.0;
			float speed_3 = 1.0;
			float phase_3 = 0.01;
			*/


			static void create_sphere(int function_index, Writer& w_definitons)
			{


				w_definitons.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitons.appendLine("{");
				{
					std::string baseRad = std::to_string(Random::generate_random_float_0_to_1() * 0.2);

					std::string amp1 = std::to_string(Random::random_float(0.02, 0.04));
					std::string freq1 = std::to_string(Random::random_float(1.0, 22));
					std::string speed1 = std::to_string(Random::random_float(-1.0, 1.0));
					std::string phase1 = std::to_string(Random::random_float(1.0, 22));

					std::string amp2 = std::to_string(Random::random_float(0.02, 0.04));
					std::string freq2 = std::to_string(Random::random_float(1.0, 22));
					std::string speed2 = std::to_string(Random::random_float(-1.0, 1.0));
					std::string phase2 = std::to_string(Random::random_float(1.0, 22));

					std::string amp3 = std::to_string(Random::random_float(0.02, 0.04));
					std::string freq3 = std::to_string(Random::random_float(1.0, 22));
					std::string speed3 = std::to_string(Random::random_float(-1.0, 1.0));
					std::string phase3 = std::to_string(Random::random_float(1.0, 22));

					Line line;
					line.add("return sdWavySphere");
					line.add("(");
					line.add("p,");
					line.add(baseRad + ",");
					line.add(amp1 + ", " + freq1 + ", " + speed1 + ", " + phase1 + ", ");
					line.add(amp2 + ", " + freq2 + ", " + speed2 + ", " + phase2 + ", ");
					line.add(amp3 + ", " + freq3 + ", " + speed3 + ", " + phase3);
					line.add(");");
					w_definitons.appendLine(line.join());
				}
				w_definitons.appendLine("}");
			}

		};

		struct TorusGeneration
		{
			static void generate_definiton(Writer& w_definitons)
			{
				w_definitons.appendLine("");
				w_definitons.appendLine("float sdWavyTorus(vec3 p, float R, float r, float waveAmp, float waveFreq, float waveSpeed) {");
				w_definitons.appendLine("	vec2 q = vec2(length(p.xz) - R, p.y);");
				w_definitons.appendLine("");
				w_definitons.appendLine("	float baseDist = length(q) - r;");
				w_definitons.appendLine("");
				w_definitons.appendLine("	vec3 localNormal = normalize(vec3(q.x * (p.x / length(p.xz)),  // x component");
				w_definitons.appendLine("		q.y,                         // y component");
				w_definitons.appendLine("		q.x * (p.z / length(p.xz))   // z component");
				w_definitons.appendLine("	));");
				w_definitons.appendLine("");
				w_definitons.appendLine("	float wave = waveAmp * sin(waveFreq * atan(p.y, length(p.xz) - R) + waveSpeed * time);");
				w_definitons.appendLine("");
				w_definitons.appendLine("	return baseDist + wave * dot(localNormal, vec3(1.0));");
				w_definitons.appendLine("}");
				w_definitons.appendLine("");
			}

			static void create_torus(int function_index, Writer& w_definitons)
			{

				w_definitons.appendLine("");
				w_definitons.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");

				w_definitons.appendLine("{");

				std::string arguments = "";

				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float R = Random::generate_random_float_0_to_1() * 0.2f;
					float r = 0.01 + Random::generate_random_float_0_to_1() * 0.1f;
					float waveAmp = 0.1 * Random::generate_random_float_0_to_1();
					float waveFreq = 0.1 * Random::generate_random_float_minus_one_to_plus_one() * 40.0;
					float waveSpeed = 0.1 * Random::generate_random_float_minus_one_to_plus_one() * 70.0;

					arguments = std::to_string(R) + ", " + std::to_string(r) + ", " + std::to_string(waveAmp) + ", " + std::to_string(waveFreq) + ", " + std::to_string(waveSpeed);
				}
				else
				{
					float R = Random::generate_random_float_0_to_1() * 0.27f;
					float r = 0.01 + Random::generate_random_float_0_to_1() * 0.1f;
					float waveAmp = 0.1 * Random::generate_random_float_0_to_1();
					float waveFreq = 0.1 * Random::generate_random_float_minus_one_to_plus_one() * 100.0;
					float waveSpeed = 0.1 * Random::generate_random_float_minus_one_to_plus_one() * 100.0;

					arguments = std::to_string(R) + ", " + std::to_string(r) + " * sin(time * 0.27), " + std::to_string(waveAmp) + ", " + std::to_string(waveFreq) + ", " + std::to_string(waveSpeed);
				}


				w_definitons.appendLine("	return sdWavyTorus(p, " + arguments + ");");

				w_definitons.appendLine("}");

				w_definitons.appendLine("");
			}

		};

		struct CylinderGeneration
		{

			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Capped Cylinder SDF (auto generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyCylinder(vec3 p, float R, float halfH, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Step 1: compute a sinusoidal wobble on the cylinder’s radius");
				w_definitions.appendLine("    float angle = atan(p.z, p.x);");
				w_definitions.appendLine("    float wave  = waveAmp * sin(waveFreq * angle + waveSpeed * time);");
				w_definitions.appendLine("    float effR  = R + wave;  // the effective radius at this ");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Step 2: build the 2D distance vector for a capped cylinder:");
				w_definitions.appendLine("    //     d.x = horizontal distance from (p.xz) to the circle of radius effR");
				w_definitions.appendLine("    //     d.y = vertical distance from p.y to the top/bottom caps halfH");
				w_definitions.appendLine("    vec2 d = vec2(length(p.xz) - effR,");
				w_definitions.appendLine("                  abs(p.y)  - halfH);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Step 3: standard SDF expression for a box in 2D (caps + side):");
				w_definitions.appendLine("    float outsideDist = length(max(d, vec2(0.0)));");
				w_definitions.appendLine("    float insideDist  = min(max(d.x, d.y), 0.0);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return outsideDist + insideDist;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_cylinder(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{

					float R = 0.05f + Random::generate_random_float_0_to_1() * 0.20f;
					float halfH = 0.05f + Random::generate_random_float_0_to_1() * 0.15f;
					float waveAmp = 0.05f * Random::generate_random_float_0_to_1();
					float waveFreq = 5.0f * Random::generate_random_float_0_to_1() *
						Random::generate_random_float_minus_one_to_plus_one() * 5.0f;
					float waveSpeed = 2.0f * Random::generate_random_float_minus_one_to_plus_one() * 10.0f;

					arguments = std::to_string(R) + ", "
						+ std::to_string(halfH) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{

					float R = 0.04f + Random::generate_random_float_0_to_1() * 0.22f;
					float halfH_base = 0.05f + Random::generate_random_float_0_to_1() * 0.10f;
					float waveAmp = 0.03f * Random::generate_random_float_0_to_1();
					float waveFreq = 10.0f * Random::generate_random_float_minus_one_to_plus_one() * 10.0f;
					float waveSpeed = 1.0f * Random::generate_random_float_minus_one_to_plus_one() * 30.0f;


					arguments = std::to_string(R) + ", "
						+ std::to_string(halfH_base) + " * sin(time * 0.33), "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}

				w_definitions.appendLine("    return sdWavyCylinder(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct CapsuleGeneration
		{

			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Capsule SDF (auto generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyCapsule(vec3 p, float halfH, float r, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("	vec3 a = vec3(0.0, -halfH, 0.0);");
				w_definitions.appendLine("	vec3 b = vec3(0.0,  halfH, 0.0);");
				w_definitions.appendLine("");
				w_definitions.appendLine("	vec3 ba = b - a;");
				w_definitions.appendLine("	vec3 pa = p - a;");
				w_definitions.appendLine("	float hparam = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);");
				w_definitions.appendLine("	vec3 proj = a + ba * hparam;");
				w_definitions.appendLine("");
				w_definitions.appendLine("	float angle = atan(p.z, p.x);");
				w_definitions.appendLine("	float wave  = waveAmp * sin(waveFreq * angle + waveSpeed * time);");
				w_definitions.appendLine("	float effR  = r + wave;  // effective radius at this ");
				w_definitions.appendLine("");
				w_definitions.appendLine("	// Step 4: distance = distance from p to the closest point on segment, minus effective radius");
				w_definitions.appendLine("	return length(p - proj) - effR;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_capsule(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{


					float halfH = 0.05f + Random::generate_random_float_0_to_1() * 0.20f;
					float r = 0.01f + Random::generate_random_float_0_to_1() * 0.10f;
					float waveAmp = 0.05f * Random::generate_random_float_0_to_1();
					float waveFreq = 20.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 50.0f * Random::generate_random_float_minus_one_to_plus_one();

					arguments = std::to_string(halfH) + ", "
						+ std::to_string(r) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{

					float halfH_base = 0.04f + Random::generate_random_float_0_to_1() * 0.22f;
					float r_base = 0.02f + Random::generate_random_float_0_to_1() * 0.08f;
					float waveAmp = 0.03f * Random::generate_random_float_0_to_1();
					float waveFreq = 30.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 20.0f * Random::generate_random_float_minus_one_to_plus_one();


					arguments = std::to_string(halfH_base) + ", "
						+ std::to_string(r_base) + " * (0.5 + 0.5 * sin(time * 0.5)), "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}

				w_definitions.appendLine("	return sdWavyCapsule(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct OctahedronGeneration
		{
			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Octahedron SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyOctahedron(vec3 p, float R, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    float rLen  = length(p);");
				w_definitions.appendLine("    if (rLen < 0.0001) {");
				w_definitions.appendLine("        return (abs(p.x) + abs(p.y) + abs(p.z) - R) / 1.73205;");
				w_definitions.appendLine("    }");
				w_definitions.appendLine("    float theta = acos(clamp(p.y / rLen, -1.0, 1.0));");
				w_definitions.appendLine("    float phi   = atan(p.z, p.x);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float wave = waveAmp * sin(waveFreq * theta + waveSpeed * time);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float effR = R + wave; // effective “edge-length” parameter");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float d = (abs(p.x) + abs(p.y) + abs(p.z) - effR) * 0.57735026919;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return d;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_octahedron(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{

					float R = 0.10f + Random::generate_random_float_0_to_1() * 0.20f;
					float waveAmp = 0.05f * Random::generate_random_float_0_to_1();
					float waveFreq = 30.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 20.0f * Random::generate_random_float_minus_one_to_plus_one();

					arguments = std::to_string(R) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{

					float baseR = 0.12f + Random::generate_random_float_0_to_1() * 0.18f;
					float waveAmp = 0.03f * Random::generate_random_float_0_to_1();
					float waveFreq = 25.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 15.0f * Random::generate_random_float_minus_one_to_plus_one();


					arguments = std::to_string(baseR) + " * (0.8 + 0.2 * sin(time * 0.5)), "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}

				w_definitions.appendLine("    return sdWavyOctahedron(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct RoundedBoxGeneration
		{

			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Rounded Box SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyRoundedBox(vec3 p, float bVal, float r, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    float angle = atan(p.z, p.x);");
				w_definitions.appendLine("    float wave  = waveAmp * sin(waveFreq * angle + waveSpeed * time);");
				w_definitions.appendLine("    float effR  = r + wave;  // effective corner radius");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 d = abs(p) - vec3(bVal);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float outside = length(max(d, vec3(0.0)));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float inside  = min(max(d.x, max(d.y, d.z)), 0.0);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return outside + inside - effR;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_rounded_box(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float bVal = 0.05f + Random::generate_random_float_0_to_1() * 0.20f;
					float r = 0.01f + Random::generate_random_float_0_to_1() * 0.09f;
					float waveAmp = 0.05f * Random::generate_random_float_0_to_1();
					float waveFreq = 30.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 40.0f * Random::generate_random_float_minus_one_to_plus_one();

					arguments = std::to_string(bVal) + ", "
						+ std::to_string(r) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{

					float baseB = 0.06f + Random::generate_random_float_0_to_1() * 0.18f; // [0.06, 0.24]
					float r = 0.02f + Random::generate_random_float_0_to_1() * 0.08f;
					float waveAmp = 0.03f * Random::generate_random_float_0_to_1();
					float waveFreq = 25.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 30.0f * Random::generate_random_float_minus_one_to_plus_one();


					arguments = std::to_string(baseB) + " * (0.7 + 0.3 * sin(time * 0.7)), "
						+ std::to_string(r) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}

				w_definitions.appendLine("    return sdWavyRoundedBox(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct TwistedTorusGeneration
		{
			// Writes the raw GLSL definition of sdWavyTwistedTorus into w_definitions
			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Twisted Torus SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyTwistedTorus(vec3 p, float R, float r, float twistAmt, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Step 1: apply a twist around the Y-axis proportional to p.y");
				w_definitions.appendLine("    float angleTwist = twistAmt * p.y;");
				w_definitions.appendLine("    float c = cos(angleTwist);");
				w_definitions.appendLine("    float s = sin(angleTwist);");
				w_definitions.appendLine("    // rotate (p.x, p.z) by ±angleTwist");
				w_definitions.appendLine("    vec3 p2 = vec3(");
				w_definitions.appendLine("        p.x * c - p.z * s,");
				w_definitions.appendLine("        p.y,");
				w_definitions.appendLine("        p.x * s + p.z * c");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Step 2: compute the “raw” torus SDF on the twisted point p2");
				w_definitions.appendLine("    vec2 q = vec2(length(p2.xz) - R, p2.y);");
				w_definitions.appendLine("    float baseDist = length(q) - r;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Step 3: compute a sinusoidal wave around the tube (use p2’s polar angle in XZ)");
				w_definitions.appendLine("    float phi   = atan(p2.z, p2.x);       // angle around Y");
				w_definitions.appendLine("    float wave  = waveAmp * sin(waveFreq * phi + waveSpeed * time);");
				w_definitions.appendLine("    float effR  = r + wave;               // tube radius modulated by the wave");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Step 4: recompute distance with wavy tube radius");
				w_definitions.appendLine("    float distWavy = length(vec2(length(p2.xz) - R, p2.y)) - effR;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return distWavy;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}

			// Writes a wrapper sd_<index>(vec3 p) that calls sdWavyTwistedTorus with randomized parameters.
			static void create_twisted_torus(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;

				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float R = 0.10f + Random::generate_random_float_0_to_1() * 0.20f;
					float r = 0.02f + Random::generate_random_float_0_to_1() * 0.08f;
					float twistAmt = 2.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveAmp = 0.05f * Random::generate_random_float_0_to_1();
					float waveFreq = 40.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 50.0f * Random::generate_random_float_minus_one_to_plus_one();

					arguments = std::to_string(R) + ", "
						+ std::to_string(r) + ", "
						+ std::to_string(twistAmt) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{
					// Alternate: make twistAmt oscillate over time: baseTwist * sin(time * 0.3)
					float baseR = 0.12f + Random::generate_random_float_0_to_1() * 0.18f;  // [0.12, 0.30]
					float baser = 0.03f + Random::generate_random_float_0_to_1() * 0.07f;  // [0.03, 0.10]
					float baseTwist = 1.5f * Random::generate_random_float_minus_one_to_plus_one(); // up to +-1.5
					float waveAmp = 0.03f * Random::generate_random_float_0_to_1();
					float waveFreq = 30.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 40.0f * Random::generate_random_float_minus_one_to_plus_one();

					// twistAmt = baseTwist * sin(time * 0.3)
					arguments = std::to_string(baseR) + ", "
						+ std::to_string(baser) + ", "
						+ std::to_string(baseTwist) + " * sin(time * 0.3), "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}

				w_definitions.appendLine("    return sdWavyTwistedTorus(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct MandelbulbGeneration
		{
			// Writes the raw GLSL definition of sdWavyMandelbulb into w_definitions
			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Mandelbulb SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyMandelbulb(vec3 p, float power, float bail, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Step 1: apply a radial wave to p so the fractal “breathes”");
				w_definitions.appendLine("    float rLen = length(p);");
				w_definitions.appendLine("    if (rLen > 0.0001) {");
				w_definitions.appendLine("        // Convert p to spherical angles");
				w_definitions.appendLine("        float theta = acos(clamp(p.z / rLen, -1.0, 1.0));");
				w_definitions.appendLine("        float phi   = atan(p.y, p.x);");
				w_definitions.appendLine("        // Compute a sine-wave offset along the radial direction");
				w_definitions.appendLine("        float wave = waveAmp * sin(waveFreq * theta + waveSpeed * time);");
				w_definitions.appendLine("        // Push p outward/inward by wave");
				w_definitions.appendLine("        p += (p / rLen) * wave;");
				w_definitions.appendLine("    }");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Step 2: standard Mandelbulb iteration");
				w_definitions.appendLine("    vec3 z = p;");
				w_definitions.appendLine("    float dr = 1.0;");
				w_definitions.appendLine("    float r   = 0.0;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // We fix ITER = 8 for a reasonable detail level");
				w_definitions.appendLine("    const int ITER = 4;");
				w_definitions.appendLine("    for (int i = 0; i < ITER; i++) {");
				w_definitions.appendLine("        r = length(z);");
				w_definitions.appendLine("        if (r > bail) {");
				w_definitions.appendLine("            break;");
				w_definitions.appendLine("        }");
				w_definitions.appendLine("        // Convert to spherical coordinates");
				w_definitions.appendLine("        float theta = acos(clamp(z.z / r, -1.0, 1.0));");
				w_definitions.appendLine("        float phi   = atan(z.y, z.x);");
				w_definitions.appendLine("");
				w_definitions.appendLine("        // Compute the derivative for distance estimation");
				w_definitions.appendLine("        dr = pow(r, power - 1.0) * power * dr + 1.0;");
				w_definitions.appendLine("");
				w_definitions.appendLine("        // Scale radius");
				w_definitions.appendLine("        float zr = pow(r, power);");
				w_definitions.appendLine("        // Multiply angles");
				w_definitions.appendLine("        theta *= power;");
				w_definitions.appendLine("        phi   *= power;");
				w_definitions.appendLine("");
				w_definitions.appendLine("        // Reconstruct z in cartesian and add the original p");
				w_definitions.appendLine("        z = zr * vec3(");
				w_definitions.appendLine("            sin(theta) * cos(phi),");
				w_definitions.appendLine("            sin(theta) * sin(phi),");
				w_definitions.appendLine("            cos(theta)");
				w_definitions.appendLine("        ) + p;");
				w_definitions.appendLine("    }");
				w_definitions.appendLine("");
				w_definitions.appendLine("    r = length(z);");
				w_definitions.appendLine("    // Distance estimator formula for Mandelbulb");
				w_definitions.appendLine("    return 0.5 * log(r) * r / dr;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}

			// Writes a wrapper sd_<index>(vec3 p) that calls sdWavyMandelbulb with randomized parameters.
			static void create_mandelbulb(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{


					float power = 2.0f + Random::generate_random_float_0_to_1() * 6.0f;
					float bail = 2.0f + Random::generate_random_float_0_to_1() * 2.0f;
					float waveAmp = 0.01f + Random::generate_random_float_0_to_1() * 0.06f;
					float waveFreq = 20.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 30.0f * Random::generate_random_float_minus_one_to_plus_one();

					arguments = std::to_string(power) + ", "
						+ std::to_string(bail) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{

					float baseBail = 2.5f + Random::generate_random_float_0_to_1() * 1.5f; // [2.5, 4.0]
					float waveAmp = 0.02f + Random::generate_random_float_0_to_1() * 0.03f;
					float waveFreq = 15.0f * Random::generate_random_float_minus_one_to_plus_one();
					float waveSpeed = 25.0f * Random::generate_random_float_minus_one_to_plus_one();


					arguments = std::string("3.0 + 1.0 * sin(time * 0.4), ")
						+ std::to_string(baseBail) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}

				w_definitions.appendLine("    return sdWavyMandelbulb(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct IcosahedronGeneration
		{

			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Icosahedron SDF (auto generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyIcosahedron(vec3 p, float edgeDist, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Step 1: compute a spherical-based wave");
				w_definitions.appendLine("    float theta = atan(p.y, p.x);");
				w_definitions.appendLine("    float wave  = waveAmp * sin(waveFreq * theta + waveSpeed * time);");
				w_definitions.appendLine("    float effE  = edgeDist + wave;");
				w_definitions.appendLine("");

				w_definitions.appendLine("    const float phi = 1.6180339887498948482;");
				w_definitions.appendLine("");

				w_definitions.appendLine("    vec3 n0  = normalize(vec3(  1.0,  phi,  0.0));");
				w_definitions.appendLine("    vec3 n1  = normalize(vec3( -1.0,  phi,  0.0));");
				w_definitions.appendLine("    vec3 n2  = normalize(vec3(  1.0, -phi,  0.0));");
				w_definitions.appendLine("    vec3 n3  = normalize(vec3( -1.0, -phi,  0.0));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 n4  = normalize(vec3(  0.0,   1.0,  phi));");
				w_definitions.appendLine("    vec3 n5  = normalize(vec3(  0.0,  -1.0,  phi));");
				w_definitions.appendLine("    vec3 n6  = normalize(vec3(  0.0,   1.0, -phi));");
				w_definitions.appendLine("    vec3 n7  = normalize(vec3(  0.0,  -1.0, -phi));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 n8  = normalize(vec3(  phi,  0.0,   1.0));");
				w_definitions.appendLine("    vec3 n9  = normalize(vec3( -phi,  0.0,   1.0));");
				w_definitions.appendLine("    vec3 n10 = normalize(vec3(  phi,  0.0,  -1.0));");
				w_definitions.appendLine("    vec3 n11 = normalize(vec3( -phi,  0.0,  -1.0));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 n12 = normalize(vec3(  1.0,   1.0,   1.0));");
				w_definitions.appendLine("    vec3 n13 = normalize(vec3( -1.0,   1.0,   1.0));");
				w_definitions.appendLine("    vec3 n14 = normalize(vec3(  1.0,  -1.0,   1.0));");
				w_definitions.appendLine("    vec3 n15 = normalize(vec3( -1.0,  -1.0,   1.0));");
				w_definitions.appendLine("    vec3 n16 = normalize(vec3(  1.0,   1.0,  -1.0));");
				w_definitions.appendLine("    vec3 n17 = normalize(vec3( -1.0,   1.0,  -1.0));");
				w_definitions.appendLine("    vec3 n18 = normalize(vec3(  1.0,  -1.0,  -1.0));");
				w_definitions.appendLine("    vec3 n19 = normalize(vec3( -1.0,  -1.0,  -1.0));");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float d0  = dot(p, n0)  - effE;");
				w_definitions.appendLine("    float d1  = dot(p, n1)  - effE;");
				w_definitions.appendLine("    float d2  = dot(p, n2)  - effE;");
				w_definitions.appendLine("    float d3  = dot(p, n3)  - effE;");
				w_definitions.appendLine("    float d4  = dot(p, n4)  - effE;");
				w_definitions.appendLine("    float d5  = dot(p, n5)  - effE;");
				w_definitions.appendLine("    float d6  = dot(p, n6)  - effE;");
				w_definitions.appendLine("    float d7  = dot(p, n7)  - effE;");
				w_definitions.appendLine("    float d8  = dot(p, n8)  - effE;");
				w_definitions.appendLine("    float d9  = dot(p, n9)  - effE;");
				w_definitions.appendLine("    float d10 = dot(p, n10) - effE;");
				w_definitions.appendLine("    float d11 = dot(p, n11) - effE;");
				w_definitions.appendLine("    float d12 = dot(p, n12) - effE;");
				w_definitions.appendLine("    float d13 = dot(p, n13) - effE;");
				w_definitions.appendLine("    float d14 = dot(p, n14) - effE;");
				w_definitions.appendLine("    float d15 = dot(p, n15) - effE;");
				w_definitions.appendLine("    float d16 = dot(p, n16) - effE;");
				w_definitions.appendLine("    float d17 = dot(p, n17) - effE;");
				w_definitions.appendLine("    float d18 = dot(p, n18) - effE;");
				w_definitions.appendLine("    float d19 = dot(p, n19) - effE;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float d = d0;");
				w_definitions.appendLine("    d = max(d, d1);  d = max(d, d2);  d = max(d, d3);");
				w_definitions.appendLine("    d = max(d, d4);  d = max(d, d5);  d = max(d, d6);");
				w_definitions.appendLine("    d = max(d, d7);  d = max(d, d8);  d = max(d, d9);");
				w_definitions.appendLine("    d = max(d, d10); d = max(d, d11); d = max(d, d12);");
				w_definitions.appendLine("    d = max(d, d13); d = max(d, d14); d = max(d, d15);");
				w_definitions.appendLine("    d = max(d, d16); d = max(d, d17); d = max(d, d18);");
				w_definitions.appendLine("    d = max(d, d19);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return d;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_icosahedron(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{

					float edgeDist = 0.5f + Random::generate_random_float_0_to_1() * 0.30f;
					float waveAmp = 0.02f + Random::generate_random_float_0_to_1() * 0.03f;
					float waveFreq = 3.0f + Random::generate_random_float_0_to_1() * 3.0f;
					float waveSpeed = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;

					arguments = std::to_string(edgeDist) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{

					float baseEdge = 0.6f + Random::generate_random_float_0_to_1() * 0.10f;
					float waveAmp = 0.02f + Random::generate_random_float_0_to_1() * 0.02f;
					float waveFreq = 3.0f + Random::generate_random_float_0_to_1() * 2.0f;
					float waveSpeed = 1.0f + Random::generate_random_float_0_to_1() * 0.5f;


					arguments = std::to_string(baseEdge) + " * (0.9 + 0.1 * sin(time * 0.5)), "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}

				w_definitions.appendLine("    return sdWavyIcosahedron(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct DancingPlanesGeneration
		{
			// Writes the raw GLSL definition of sdDancingPlanes into w_definitions
			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Dancing Planes SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdDancingPlanes(");
				w_definitions.appendLine("    vec3 p,");
				w_definitions.appendLine("    float baseHalf,");
				w_definitions.appendLine("    float ampX, float freqX, float speedX,");
				w_definitions.appendLine("    float ampY, float freqY, float speedY,");
				w_definitions.appendLine("    float ampZ, float freqZ, float speedZ");
				w_definitions.appendLine(")");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    float hx = baseHalf + ampX * sin(freqX * time + speedX);");
				w_definitions.appendLine("    float hy = baseHalf + ampY * sin(freqY * time + speedY);");
				w_definitions.appendLine("    float hz = baseHalf + ampZ * sin(freqZ * time + speedZ);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 d = vec3(abs(p.x) - hx,");
				w_definitions.appendLine("                  abs(p.y) - hy,");
				w_definitions.appendLine("                  abs(p.z) - hz);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float outside = length(max(d, vec3(0.0)));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float inside = min(max(d.x, max(d.y, d.z)), 0.0);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return outside + inside;");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}

			static void create_dancing_planes(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;

				// We want the six dancing planes to stay inside [-1,1]^3 at all times.

				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					// Primary branch: all parameters random but constrained so the box stays within the cube.
					float baseHalf = 0.20f + Random::generate_random_float_0_to_1() * 0.20f;  // [0.2, 0.4]
					float ampX = 0.05f + Random::generate_random_float_0_to_1() * 0.10f;  // [0.05,0.15]
					float freqX = 1.0f + Random::generate_random_float_0_to_1() * 3.0f;   // [1,4]
					float speedX = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;   // [1,3]
					float ampY = 0.05f + Random::generate_random_float_0_to_1() * 0.10f;  // [0.05,0.15]
					float freqY = 1.0f + Random::generate_random_float_0_to_1() * 3.0f;   // [1,4]
					float speedY = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;   // [1,3]
					float ampZ = 0.05f + Random::generate_random_float_0_to_1() * 0.10f;  // [0.05,0.15]
					float freqZ = 1.0f + Random::generate_random_float_0_to_1() * 3.0f;   // [1,4]
					float speedZ = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;   // [1,3]

					arguments = std::to_string(baseHalf) + ", "
						+ std::to_string(ampX) + ", " + std::to_string(freqX) + ", " + std::to_string(speedX) + ", "
						+ std::to_string(ampY) + ", " + std::to_string(freqY) + ", " + std::to_string(speedY) + ", "
						+ std::to_string(ampZ) + ", " + std::to_string(freqZ) + ", " + std::to_string(speedZ);
				}
				else
				{
					// Alternate branch: let baseHalf itself oscillate slightly over time for extra “dance.”
					float baseBase = 0.25f + Random::generate_random_float_0_to_1() * 0.10f;  // [0.25,0.35]
					float ampX = 0.04f + Random::generate_random_float_0_to_1() * 0.08f;  // [0.04,0.12]
					float freqX = 1.5f + Random::generate_random_float_0_to_1() * 2.0f;   // [1.5,3.5]
					float speedX = 1.0f + Random::generate_random_float_0_to_1() * 1.5f;   // [1,2.5]
					float ampY = 0.04f + Random::generate_random_float_0_to_1() * 0.08f;  // [0.04,0.12]
					float freqY = 1.5f + Random::generate_random_float_0_to_1() * 2.0f;   // [1.5,3.5]
					float speedY = 1.0f + Random::generate_random_float_0_to_1() * 1.5f;   // [1,2.5]
					float ampZ = 0.04f + Random::generate_random_float_0_to_1() * 0.08f;  // [0.04,0.12]
					float freqZ = 1.5f + Random::generate_random_float_0_to_1() * 2.0f;   // [1.5,3.5]
					float speedZ = 1.0f + Random::generate_random_float_0_to_1() * 1.5f;   // [1,2.5]

					// baseHalf = baseBase * (0.8 + 0.2 * sin(time * 0.5))
					arguments = std::to_string(baseBase) + " * (0.8 + 0.2 * sin(time * 0.5)), "
						+ std::to_string(ampX) + ", " + std::to_string(freqX) + ", " + std::to_string(speedX) + ", "
						+ std::to_string(ampY) + ", " + std::to_string(freqY) + ", " + std::to_string(speedY) + ", "
						+ std::to_string(ampZ) + ", " + std::to_string(freqZ) + ", " + std::to_string(speedZ);
				}

				w_definitions.appendLine("    return sdDancingPlanes(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct WaterInCubeGeneration
		{

			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Wavy Water in a Cube SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWavyWaterInCube(");
				w_definitions.appendLine("    vec3 p,");
				w_definitions.appendLine("    float baseHeight,");
				w_definitions.appendLine("    float amp, float freqX, float freqZ, float speedX, float speedZ");
				w_definitions.appendLine(")");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    float waveX = sin(freqX * p.x + speedX * time);");
				w_definitions.appendLine("    float waveZ = sin(freqZ * p.z + speedZ * time);");
				w_definitions.appendLine("    float waterH = baseHeight + amp * waveX * waveZ;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float dWater = p.y - waterH;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float dCube = max(");
				w_definitions.appendLine("        max(abs(p.x) - 1.0,");
				w_definitions.appendLine("            abs(p.y) - 1.0),");
				w_definitions.appendLine("        abs(p.z) - 1.0");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return max(dWater, dCube);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}

			static void create_water_in_cube(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float baseHeight = -0.7f + Random::generate_random_float_0_to_1() * 0.30f;
					float amp = 0.05f + Random::generate_random_float_0_to_1() * 0.10f;
					float freqX = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;
					float freqZ = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;
					float speedX = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;
					float speedZ = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;

					arguments = std::to_string(baseHeight) + ", "
						+ std::to_string(amp) + ", "
						+ std::to_string(freqX) + ", "
						+ std::to_string(freqZ) + ", "
						+ std::to_string(speedX) + ", "
						+ std::to_string(speedZ);
				}
				else
				{

					float baseBase = -0.6f + Random::generate_random_float_0_to_1() * 0.10f;
					float amp = 0.04f + Random::generate_random_float_0_to_1() * 0.08f;
					float freqX = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;
					float freqZ = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;
					float speedX = 1.0f + Random::generate_random_float_0_to_1() * 0.8f;
					float speedZ = 1.0f + Random::generate_random_float_0_to_1() * 0.8f;

					arguments = std::to_string(baseBase) + " * (0.8 + 0.2 * sin(time * 0.4)), "
						+ std::to_string(amp) + ", "
						+ std::to_string(freqX) + ", "
						+ std::to_string(freqZ) + ", "
						+ std::to_string(speedX) + ", "
						+ std::to_string(speedZ);
				}

				w_definitions.appendLine("    return sdWavyWaterInCube(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct CubismMotionGeneration
		{

			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Cubism Motion-Graphic in a Cube SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdCubismCubes(");
				w_definitions.appendLine("    vec3 p,");
				w_definitions.appendLine("    float h1, float h2, float h3,    // half-extents of cube1, cube2, cube3");
				w_definitions.appendLine("    float speedX, float speedY, float speedZ  // rotation speeds (rad/sec)");
				w_definitions.appendLine(")");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Compute rotation angles from time");
				w_definitions.appendLine("    float ax = speedX * time;");
				w_definitions.appendLine("    float ay = speedY * time;");
				w_definitions.appendLine("    float az = speedZ * time;");
				w_definitions.appendLine("");

				w_definitions.appendLine("    vec3 p1 = vec3(");
				w_definitions.appendLine("        p.x,");
				w_definitions.appendLine("        cos(ax)*p.y - sin(ax)*p.z,");
				w_definitions.appendLine("        sin(ax)*p.y + cos(ax)*p.z");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    vec3 p2 = vec3(");
				w_definitions.appendLine("        cos(ay)*p.x + sin(ay)*p.z,");
				w_definitions.appendLine("        p.y,");
				w_definitions.appendLine("        -sin(ay)*p.x + cos(ay)*p.z");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    vec3 p3 = vec3(");
				w_definitions.appendLine("        cos(az)*p.x - sin(az)*p.y,");
				w_definitions.appendLine("        sin(az)*p.x + cos(az)*p.y,");
				w_definitions.appendLine("        p.z");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    vec3 b1 = vec3(h1);");
				w_definitions.appendLine("    vec3 d1a = abs(p1) - b1;");
				w_definitions.appendLine("    float outside1 = length(max(d1a, vec3(0.0)));");
				w_definitions.appendLine("    float inside1  = min(max(d1a.x, max(d1a.y, d1a.z)), 0.0);");
				w_definitions.appendLine("    float d1 = outside1 + inside1;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 b2 = vec3(h2);");
				w_definitions.appendLine("    vec3 d2a = abs(p2) - b2;");
				w_definitions.appendLine("    float outside2 = length(max(d2a, vec3(0.0)));");
				w_definitions.appendLine("    float inside2  = min(max(d2a.x, max(d2a.y, d2a.z)), 0.0);");
				w_definitions.appendLine("    float d2 = outside2 + inside2;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 b3 = vec3(h3);");
				w_definitions.appendLine("    vec3 d3a = abs(p3) - b3;");
				w_definitions.appendLine("    float outside3 = length(max(d3a, vec3(0.0)));");
				w_definitions.appendLine("    float inside3  = min(max(d3a.x, max(d3a.y, d3a.z)), 0.0);");
				w_definitions.appendLine("    float d3 = outside3 + inside3;");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float dUnion = min(min(d1, d2), d3);");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float dCube = max(");
				w_definitions.appendLine("        max(abs(p.x) - 1.0,");
				w_definitions.appendLine("            abs(p.y) - 1.0),");
				w_definitions.appendLine("        abs(p.z) - 1.0");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    return max(dUnion, dCube);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_cubism(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;



				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float h1 = 0.40f + Random::generate_random_float_0_to_1() * 0.20f;  // [0.4,0.6]
					float h2 = 0.30f + Random::generate_random_float_0_to_1() * 0.20f;  // [0.3,0.5]
					float h3 = 0.20f + Random::generate_random_float_0_to_1() * 0.20f;  // [0.2,0.4]
					float speedX = 0.5f + Random::generate_random_float_0_to_1() * 1.5f;   // [0.5,2.0]
					float speedY = 0.5f + Random::generate_random_float_0_to_1() * 1.5f;   // [0.5,2.0]
					float speedZ = 0.5f + Random::generate_random_float_0_to_1() * 1.5f;   // [0.5,2.0]

					arguments = std::to_string(h1) + ", "
						+ std::to_string(h2) + ", "
						+ std::to_string(h3) + ", "
						+ std::to_string(speedX) + ", "
						+ std::to_string(speedY) + ", "
						+ std::to_string(speedZ);
				}
				else
				{

					// Speeds still small so things stay smooth.
					float baseH1 = 0.45f + Random::generate_random_float_0_to_1() * 0.10f; // [0.45,0.55]
					float baseH2 = 0.35f + Random::generate_random_float_0_to_1() * 0.10f; // [0.35,0.45]
					float baseH3 = 0.25f + Random::generate_random_float_0_to_1() * 0.10f; // [0.25,0.35]
					float speedX = 0.6f + Random::generate_random_float_0_to_1() * 1.4f;  // [0.6,2.0]
					float speedY = 0.6f + Random::generate_random_float_0_to_1() * 1.4f;  // [0.6,2.0]
					float speedZ = 0.6f + Random::generate_random_float_0_to_1() * 1.4f;  // [0.6,2.0]

					// h1 = baseH1 * (0.8 + 0.2*sin(time*0.4)), etc.
					std::ostringstream argStream;
					argStream << baseH1 << " * (0.8 + 0.2 * sin(time * 0.4))" << ", "
						<< baseH2 << " * (0.8 + 0.2 * sin(time * 0.5))" << ", "
						<< baseH3 << " * (0.8 + 0.2 * sin(time * 0.6))" << ", "
						<< speedX << ", " << speedY << ", " << speedZ;
					arguments = argStream.str();
				}

				w_definitions.appendLine("    return sdCubismCubes(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct SwirlingHelixGeneration
		{
			// Emits the GLSL definition of sdSwirlingHelix into w_definitions
			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Swirling Helix Motion Graphic in a Cube SDF (auto generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdSwirlingHelix(vec3 p, float R, float tubeR, float k, float rotSpeed, float waveAmp, float waveFreq, float waveSpeed)");
				w_definitions.appendLine("{");

				w_definitions.appendLine("    float ang = rotSpeed * time;");
				w_definitions.appendLine("    float cA = cos(ang);");
				w_definitions.appendLine("    float sA = sin(ang);");
				w_definitions.appendLine("    vec3 pr = vec3(");
				w_definitions.appendLine("        cA * p.x - sA * p.z,");
				w_definitions.appendLine("        p.y,");
				w_definitions.appendLine("        sA * p.x + cA * p.z");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float rC = length(pr.xz);");
				w_definitions.appendLine("    float phi = atan(pr.z, pr.x);");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float tubeR_eff = tubeR + waveAmp * sin(waveFreq * phi + waveSpeed * time);");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float yp = pr.y - k * phi;");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float dHelix = length(vec2(rC - R, yp)) - tubeR_eff;");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float dCube = max(");
				w_definitions.appendLine("        max(abs(p.x) - 1.0,");
				w_definitions.appendLine("            abs(p.y) - 1.0),");
				w_definitions.appendLine("        abs(p.z) - 1.0");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    return max(dHelix, dCube);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_swirling_helix(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;



				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float R = 0.30f + Random::generate_random_float_0_to_1() * 0.20f;  // [0.3,0.5]
					float tubeR = 0.05f + Random::generate_random_float_0_to_1() * 0.05f;  // [0.05,0.10]
					float k = 0.10f + Random::generate_random_float_0_to_1() * 0.20f;  // [0.10,0.30]
					float rotSpeed = 0.5f + Random::generate_random_float_0_to_1() * 1.0f;   // [0.5,1.5]
					float waveAmp = 0.02f + Random::generate_random_float_0_to_1() * 0.03f;  // [0.02,0.05]
					float waveFreq = 2.0f + Random::generate_random_float_0_to_1() * 2.0f;   // [2,4]
					float waveSpeed = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;   // [1,2]

					arguments = std::to_string(R) + ", "
						+ std::to_string(tubeR) + ", "
						+ std::to_string(k) + ", "
						+ std::to_string(rotSpeed) + ", "
						+ std::to_string(waveAmp) + ", "
						+ std::to_string(waveFreq) + ", "
						+ std::to_string(waveSpeed);
				}
				else
				{


					float baseR = 0.35f + Random::generate_random_float_0_to_1() * 0.10f; // [0.35,0.45]
					float baseK = 0.12f + Random::generate_random_float_0_to_1() * 0.10f; // [0.12,0.22]
					float tubeR = 0.05f + Random::generate_random_float_0_to_1() * 0.03f; // [0.05,0.08]
					float rotSpeed = 0.6f + Random::generate_random_float_0_to_1() * 0.60f; // [0.6,1.2]
					float waveAmp = 0.02f + Random::generate_random_float_0_to_1() * 0.02f; // [0.02,0.04]
					float waveFreq = 2.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [2,3]
					float waveSpeed = 1.0f + Random::generate_random_float_0_to_1() * 0.50f; // [1,1.5]

					// R = baseR * (0.9 + 0.1 * sin(time*0.4))
					// k = baseK * (0.9 + 0.1 * sin(time*0.5))
					std::ostringstream argStream;
					argStream << baseR << " * (0.9 + 0.1 * sin(time * 0.4))" << ", "
						<< tubeR << ", "
						<< baseK << " * (0.9 + 0.1 * sin(time * 0.5))" << ", "
						<< rotSpeed << ", "
						<< waveAmp << ", "
						<< waveFreq << ", "
						<< waveSpeed;
					arguments = argStream.str();
				}

				w_definitions.appendLine("    return sdSwirlingHelix(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct SwirlingRibbonsGeneration
		{

			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Swirling Ribbons in a Cube SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdSwirlingRibbons(vec3 p,");
				w_definitions.appendLine("    float A1, float f1, float s1, float t1,");
				w_definitions.appendLine("    float A2, float f2, float s2, float t2,");
				w_definitions.appendLine("    float A3, float f3, float s3, float t3");
				w_definitions.appendLine(")");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    float wave1 = A1 * sin(f1 * p.x + s1 * time);");
				w_definitions.appendLine("    float d1 = abs(p.y - wave1) - t1;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float wave2 = A2 * sin(f2 * p.y + s2 * time);");
				w_definitions.appendLine("    float d2 = abs(p.z - wave2) - t2;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float wave3 = A3 * sin(f3 * p.z + s3 * time);");
				w_definitions.appendLine("    float d3 = abs(p.x - wave3) - t3;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float dUnion = min(min(d1, d2), d3);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    float dCube = max(");
				w_definitions.appendLine("        max(abs(p.x) - 1.0,");
				w_definitions.appendLine("            abs(p.y) - 1.0),");
				w_definitions.appendLine("        abs(p.z) - 1.0");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return max(dUnion, dCube);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}

			static void create_swirling_ribbons(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					// Ribbon 1 parameters
					float A1 = 0.30f + Random::generate_random_float_0_to_1() * 0.30f; // [0.3,0.6]
					float f1 = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;  // [1,3]
					float s1 = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [1,2]
					float t1 = 0.05f + Random::generate_random_float_0_to_1() * 0.05f; // [0.05,0.10]

					// Ribbon 2 parameters
					float A2 = 0.30f + Random::generate_random_float_0_to_1() * 0.30f; // [0.3,0.6]
					float f2 = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;  // [1,3]
					float s2 = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [1,2]
					float t2 = 0.05f + Random::generate_random_float_0_to_1() * 0.05f; // [0.05,0.10]

					// Ribbon 3 parameters
					float A3 = 0.30f + Random::generate_random_float_0_to_1() * 0.30f; // [0.3,0.6]
					float f3 = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;  // [1,3]
					float s3 = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [1,2]
					float t3 = 0.05f + Random::generate_random_float_0_to_1() * 0.05f; // [0.05,0.10]

					std::ostringstream oss;
					oss << A1 << ", " << f1 << ", " << s1 << ", " << t1 << ", "
						<< A2 << ", " << f2 << ", " << s2 << ", " << t2 << ", "
						<< A3 << ", " << f3 << ", " << s3 << ", " << t3;
					arguments = oss.str();
				}
				else
				{


					float baseA1 = 0.35f + Random::generate_random_float_0_to_1() * 0.20f; // [0.35,0.55]
					float f1 = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [1,2]
					float s1 = 1.0f + Random::generate_random_float_0_to_1() * 0.5f;  // [1,1.5]
					float t1 = 0.05f + Random::generate_random_float_0_to_1() * 0.03f; // [0.05,0.08]

					float baseA2 = 0.35f + Random::generate_random_float_0_to_1() * 0.20f; // [0.35,0.55]
					float f2 = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [1,2]
					float s2 = 1.0f + Random::generate_random_float_0_to_1() * 0.5f;  // [1,1.5]
					float t2 = 0.05f + Random::generate_random_float_0_to_1() * 0.03f; // [0.05,0.08]

					float baseA3 = 0.35f + Random::generate_random_float_0_to_1() * 0.20f; // [0.35,0.55]
					float f3 = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [1,2]
					float s3 = 1.0f + Random::generate_random_float_0_to_1() * 0.5f;  // [1,1.5]
					float t3 = 0.05f + Random::generate_random_float_0_to_1() * 0.03f; // [0.05,0.08]

					std::ostringstream oss;
					oss << baseA1 << " * (0.8 + 0.2 * sin(time * 0.4)), "
						<< f1 << ", " << s1 << ", " << t1 << ", "
						<< baseA2 << " * (0.8 + 0.2 * sin(time * 0.5)), "
						<< f2 << ", " << s2 << ", " << t2 << ", "
						<< baseA3 << " * (0.8 + 0.2 * sin(time * 0.6)), "
						<< f3 << ", " << s3 << ", " << t3;
					arguments = oss.str();
				}

				w_definitions.appendLine("    return sdSwirlingRibbons(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct TwistingTorusGeneration
		{
			// Emits the GLSL definition of sdTwistingTorus into w_definitions
			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Twisting Torus Motion Graphic in a Cube SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdTwistingTorus(vec3 p, float R, float r, float twistFreq, float twistAmp, float rotSpeed)");
				w_definitions.appendLine("{");

				w_definitions.appendLine("    float ang = twistAmp * sin(twistFreq * p.y + rotSpeed * time);");
				w_definitions.appendLine("    float c = cos(ang);");
				w_definitions.appendLine("    float s = sin(ang);");
				w_definitions.appendLine("");

				w_definitions.appendLine("    vec3 pr = vec3(");
				w_definitions.appendLine("        c * p.x - s * p.z,");
				w_definitions.appendLine("        p.y,");
				w_definitions.appendLine("        s * p.x + c * p.z");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    vec2 q = vec2(length(pr.xz) - R, pr.y);");
				w_definitions.appendLine("    float dTorus = length(q) - r;");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float dCube = max(");
				w_definitions.appendLine("        max(abs(p.x) - 1.0,");
				w_definitions.appendLine("            abs(p.y) - 1.0),");
				w_definitions.appendLine("        abs(p.z) - 1.0");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Intersection: twisting torus inside the cube");
				w_definitions.appendLine("    return max(dTorus, dCube);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_twisting_torus(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;



				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float R = 0.30f + Random::generate_random_float_0_to_1() * 0.20f;  // [0.30,0.50]
					float r = 0.05f + Random::generate_random_float_0_to_1() * 0.05f;  // [0.05,0.10]
					float twistFreq = 1.0f + Random::generate_random_float_0_to_1() * 2.0f;   // [1.0,3.0]
					float twistAmp = 0.20f + Random::generate_random_float_0_to_1() * 0.30f;  // [0.20,0.50]
					float rotSpeed = 0.50f + Random::generate_random_float_0_to_1() * 1.00f;  // [0.50,1.50]

					arguments = std::to_string(R) + ", "
						+ std::to_string(r) + ", "
						+ std::to_string(twistFreq) + ", "
						+ std::to_string(twistAmp) + ", "
						+ std::to_string(rotSpeed);
				}
				else
				{


					float baseR = 0.35f + Random::generate_random_float_0_to_1() * 0.10f; // [0.35,0.45]
					float r = 0.05f + Random::generate_random_float_0_to_1() * 0.03f; // [0.05,0.08]
					float baseAmp = 0.25f + Random::generate_random_float_0_to_1() * 0.15f; // [0.25,0.40]
					float twistFreq = 1.0f + Random::generate_random_float_0_to_1() * 1.0f;  // [1.0,2.0]
					float rotSpeed = 0.60f + Random::generate_random_float_0_to_1() * 0.60f; // [0.60,1.20]

					// R = baseR * (0.9 + 0.1*sin(time*0.4))
					// twistAmp = baseAmp * (0.9 + 0.1*sin(time*0.5))
					std::ostringstream argStream;
					argStream << baseR << " * (0.9 + 0.1 * sin(time * 0.4))" << ", "
						<< r << ", "
						<< twistFreq << ", "
						<< baseAmp << " * (0.9 + 0.1 * sin(time * 0.5))" << ", "
						<< rotSpeed;
					arguments = argStream.str();
				}

				w_definitions.appendLine("    return sdTwistingTorus(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct WindyJoyGeneration
		{
			// Emits the GLSL definition of sdWindyJoy into w_definitions
			static void generate_definition(Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("// GLSL: Windy Joy Motion Graphic in a Cube SDF (auto-generated)");
				w_definitions.appendLine("// -------------------------------------------------------------");
				w_definitions.appendLine("");
				w_definitions.appendLine("float sdWindyJoy(vec3 p, float rBase, float ampX, float ampY, float freqX, float freqY, float speedX, float speedY)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Compute three drifting sphere centers to evoke wind and joy");
				w_definitions.appendLine("    vec3 c1 = vec3(");
				w_definitions.appendLine("        sin(freqX * time * speedX) * ampX,");
				w_definitions.appendLine("        cos(freqY * time * speedY) * ampY,");
				w_definitions.appendLine("        0.4");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 c2 = vec3(");
				w_definitions.appendLine("        -sin(freqY * time * speedY) * ampX,");
				w_definitions.appendLine("        sin(freqX * time * speedX) * ampY,");
				w_definitions.appendLine("        -0.4");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");
				w_definitions.appendLine("    vec3 c3 = vec3(");
				w_definitions.appendLine("        sin(freqX * time * speedX + 1.0) * ampX,");
				w_definitions.appendLine("        -cos(freqY * time * speedY + 1.0) * ampY,");
				w_definitions.appendLine("        0.0");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Distances to each sphere minus base radius");
				w_definitions.appendLine("    float d1 = length(p - c1) - rBase;");
				w_definitions.appendLine("    float d2 = length(p - c2) - rBase;");
				w_definitions.appendLine("    float d3 = length(p - c3) - rBase;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Union of the three joyful spheres");
				w_definitions.appendLine("    float dUnion = min(min(d1, d2), d3);");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float dCube = max(");
				w_definitions.appendLine("        max(abs(p.x) - 1.0,");
				w_definitions.appendLine("            abs(p.y) - 1.0),");
				w_definitions.appendLine("        abs(p.z) - 1.0");
				w_definitions.appendLine("    );");
				w_definitions.appendLine("");

				w_definitions.appendLine("    return max(dUnion, dCube);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}


			static void create_windy_joy(int function_index, Writer& w_definitions)
			{
				w_definitions.appendLine("");
				w_definitions.appendLine("float sd_" + std::to_string(function_index) + "(in vec3 p)");
				w_definitions.appendLine("{");

				std::string arguments;


				if (Random::generate_random_float_0_to_1() > 0.2f)
				{
					float rBase = 0.08f + Random::generate_random_float_0_to_1() * 0.07f;   // [0.08,0.15]
					float ampX = 0.30f + Random::generate_random_float_0_to_1() * 0.20f;   // [0.30,0.50]
					float ampY = 0.30f + Random::generate_random_float_0_to_1() * 0.20f;   // [0.30,0.50]
					float freqX = 0.50f + Random::generate_random_float_0_to_1() * 1.00f;   // [0.50,1.50]
					float freqY = 0.50f + Random::generate_random_float_0_to_1() * 1.00f;   // [0.50,1.50]
					float speedX = 0.50f + Random::generate_random_float_0_to_1() * 1.00f;   // [0.50,1.50]
					float speedY = 0.50f + Random::generate_random_float_0_to_1() * 1.00f;   // [0.50,1.50]

					arguments = std::to_string(rBase) + ", "
						+ std::to_string(ampX) + ", "
						+ std::to_string(ampY) + ", "
						+ std::to_string(freqX) + ", "
						+ std::to_string(freqY) + ", "
						+ std::to_string(speedX) + ", "
						+ std::to_string(speedY);
				}
				else
				{

					float baseR = 0.10f + Random::generate_random_float_0_to_1() * 0.03f;  // [0.10,0.13]
					float baseAmpX = 0.35f + Random::generate_random_float_0_to_1() * 0.10f;  // [0.35,0.45]
					float baseAmpY = 0.35f + Random::generate_random_float_0_to_1() * 0.10f;  // [0.35,0.45]
					float freqX = 0.50f + Random::generate_random_float_0_to_1() * 0.50f;  // [0.50,1.00]
					float freqY = 0.50f + Random::generate_random_float_0_to_1() * 0.50f;  // [0.50,1.00]
					float speedX = 0.60f + Random::generate_random_float_0_to_1() * 0.60f;  // [0.60,1.20]
					float speedY = 0.60f + Random::generate_random_float_0_to_1() * 0.60f;  // [0.60,1.20]

					std::ostringstream argStream;
					argStream << baseR << " * (0.9 + 0.1 * sin(time * 0.5))" << ", "
						<< baseAmpX << " * (0.9 + 0.1 * sin(time * 0.6))" << ", "
						<< baseAmpY << " * (0.9 + 0.1 * sin(time * 0.7))" << ", "
						<< freqX << ", "
						<< freqY << ", "
						<< speedX << ", "
						<< speedY;
					arguments = argStream.str();
				}

				w_definitions.appendLine("    return sdWindyJoy(p, " + arguments + ");");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};


		// generate the definitions

		WaveSphere::generate_definiton(w_definitons);
		TorusGeneration::generate_definiton(w_definitons);
		CylinderGeneration::generate_definition(w_definitons);
		CapsuleGeneration::generate_definition(w_definitons);
		OctahedronGeneration::generate_definition(w_definitons);
		RoundedBoxGeneration::generate_definition(w_definitons);
		TwistedTorusGeneration::generate_definition(w_definitons);
		MandelbulbGeneration::generate_definition(w_definitons);
		IcosahedronGeneration::generate_definition(w_definitons);
		DancingPlanesGeneration::generate_definition(w_definitons);
		WaterInCubeGeneration::generate_definition(w_definitons);
		CubismMotionGeneration::generate_definition(w_definitons);
		SwirlingHelixGeneration::generate_definition(w_definitons);
		TwistingTorusGeneration::generate_definition(w_definitons);
		WindyJoyGeneration::generate_definition(w_definitons);

		// generated sdf 

		std::vector<std::function<void(int, Writer&)>> vector_functions_sdf;
		vector_functions_sdf.push_back(WaveSphere::create_sphere);
		vector_functions_sdf.push_back(TorusGeneration::create_torus);
		vector_functions_sdf.push_back(CylinderGeneration::create_cylinder);
		vector_functions_sdf.push_back(CapsuleGeneration::create_capsule);
		vector_functions_sdf.push_back(OctahedronGeneration::create_octahedron);
		vector_functions_sdf.push_back(RoundedBoxGeneration::create_rounded_box);
		vector_functions_sdf.push_back(TwistedTorusGeneration::create_twisted_torus);
		vector_functions_sdf.push_back(MandelbulbGeneration::create_mandelbulb);
		vector_functions_sdf.push_back(IcosahedronGeneration::create_icosahedron);
		vector_functions_sdf.push_back(DancingPlanesGeneration::create_dancing_planes);
		vector_functions_sdf.push_back(WaterInCubeGeneration::create_water_in_cube);
		vector_functions_sdf.push_back(CubismMotionGeneration::create_cubism);
		vector_functions_sdf.push_back(SwirlingHelixGeneration::create_swirling_helix);
		vector_functions_sdf.push_back(TwistingTorusGeneration::create_twisting_torus);
		vector_functions_sdf.push_back(WindyJoyGeneration::create_windy_joy);

		for (int i = 0; i < 10; i++)
		{
			Random::random_element(vector_functions_sdf)(i, w_definitons);
		}


		// Textures

		struct WaveSphereTexture
		{



			static void generate_texture(Writer& w_definitons, int index)
			{

				std::string texture_name = "texture_wave_" + std::to_string(index);

				std::string frequency_g0_0 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 10.0);
				std::string frequency_g0_1 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 10.0);

				std::string frequency_g1_0 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 10.0);
				std::string frequency_g1_1 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 10.0);

				std::string frequency_g2_0 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 10.0);
				std::string frequency_g2_1 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 10.0);

				std::string frequency_g = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 1000.0);
				std::string amplitude_g = std::to_string(Random::generate_random_float_0_to_1() * 0.4);


				std::string pallete_name = "palette_generated_" + std::to_string(index);

				{
					/*
					vec3 palette(float t)
					{
						vec3 a = vec3(0.5, 0.5, 0.5);
						vec3 b = vec3(0.5, 0.5, 0.5);
						vec3 c = vec3(1.0, 1.0, 1.0);
						vec3 d = vec3(0.263, 0.416, 0.557);

						return a + b * cos(6.28318 * (c * t + d));
					}
					*/

					w_definitons.appendLine("");

					w_definitons.appendLine("vec3 " + pallete_name + "(float t)");
					w_definitons.appendLine("{");
					w_definitons.appendLine("	vec3 a = vec3(" + std::to_string(Random::random_float(0.4, 0.7)) + ", " + std::to_string(Random::random_float(0.4, 0.7)) + ", " + std::to_string(Random::random_float(0.4, 0.7)) + ");");
					w_definitons.appendLine("	vec3 b = vec3(" + std::to_string(Random::random_float(0.4, 0.7)) + ", " + std::to_string(Random::random_float(0.4, 0.7)) + ", " + std::to_string(Random::random_float(0.4, 0.7)) + ");");
					w_definitons.appendLine("	vec3 c = vec3(" + std::to_string(Random::generate_random_float_0_to_1()) + ", " + std::to_string(Random::generate_random_float_0_to_1()) + ", " + std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitons.appendLine("	vec3 d = vec3(" + std::to_string(Random::generate_random_float_0_to_1()) + ", " + std::to_string(Random::generate_random_float_0_to_1()) + ", " + std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitons.appendLine("	");
					w_definitons.appendLine("	return a + b * cos(6.28318 * (c * t + d));");
					w_definitons.appendLine("}");

					w_definitons.appendLine("");


				}



				w_definitons.appendLine("");
				w_definitons.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitons.appendLine("{");
				w_definitons.appendLine("	");
				w_definitons.appendLine("	float d0 = dot(vec3(1.0, 0.0, 0.0), ray.normal);");
				w_definitons.appendLine("	float d1 = dot(vec3(0.0, 1.0, 0.0), ray.normal);");
				w_definitons.appendLine("	float d2 = dot(vec3(1.0, 0.0, 1.0), ray.normal);");
				w_definitons.appendLine("	");
				w_definitons.appendLine("	float g0 = min(1.0, pow(abs(sin(ray.p.x * " + frequency_g0_0 + "))* abs(sin(ray.p.z * " + frequency_g0_1 + ")), 0.5)); ");
				w_definitons.appendLine("	float g1 = min(1.0, pow(abs(sin(ray.p.x * " + frequency_g1_0 + "))* abs(sin(ray.p.y * " + frequency_g1_1 + ")), 0.5)); ");
				w_definitons.appendLine("	float g2 = min(1.0, pow(abs(sin(ray.p.x * " + frequency_g2_0 + "))* abs(sin(ray.p.y * " + frequency_g2_1 + ")), 0.5)); ");
				w_definitons.appendLine("	");
				w_definitons.appendLine("	vec3 v0 = " + pallete_name + "(sin((d0 * g0 * d1 * g1 * d2 * g2) * " + frequency_g + ")); ");
				w_definitons.appendLine("	vec3 v1 = " + pallete_name + "((d0 * g0 + d1 * g1 + d2 * g2) * (1.0 / 3.0));");
				w_definitons.appendLine("	return v1 * (0.75 + " + amplitude_g + " * v0); ");
				w_definitons.appendLine("}");
				w_definitons.appendLine("");
			}
			/*
			vec3 texture_0000(Ray ray)
			{
				vec3 color = vec3(0.0, 0.0, 0.0);

				float d0 = dot(vec3(1.0, 0.0, 0.0), ray.normal);
				float d1 = dot(vec3(0.0, 1.0, 0.0), ray.normal);
				float d2 = dot(vec3(1.0, 0.0, 1.0), ray.normal);

				float g0 = min(1.0, pow(abs(sin(ray.p.x * 10)) * abs(sin(ray.p.z * 10)), 0.5));
				float g1 = min(1.0, pow(abs(sin(ray.p.x * 10)) * abs(sin(ray.p.y * 10)), 0.5));
				float g2 = min(1.0, pow(abs(sin(ray.p.y * 10)) * abs(sin(ray.p.z * 10)), 0.5));


				vec3 v0 = palette(sin((d0 * g0 * d1 * g1 * d2 * g2) * 420.0));
				vec3 v1 = palette((d0 * g0 + d1 * g1 + d2 * g2) * (1.0 / 3.0));
				return v1 * (0.75 + 0.25 * v0);
			}
			*/
		};

		struct WarpedRippleTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{
				std::string texture_name = "texture_wave_" + std::to_string(index);
				std::string palette_name = "palette_generated_" + std::to_string(index);

				std::string ripple_freq_x = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 2.0);
				std::string ripple_freq_y = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 2.0);

				std::string distortion_x = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 4.5);
				std::string distortion_y = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 4.5);

				std::string frequency_g = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 4.0);
				std::string amplitude_g = std::to_string(Random::generate_random_float_0_to_1() * 0.5);

				// Define playful palette function
				{
					w_definitions.appendLine("");
					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 baseColor = vec3(" + std::to_string(Random::random_float(0.2, 0.6)) + ", " + std::to_string(Random::random_float(0.2, 0.6)) + ", " + std::to_string(Random::random_float(0.2, 0.6)) + ");");
					w_definitions.appendLine("    vec3 waveColor = vec3(" + std::to_string(Random::random_float(0.6, 1.0)) + ", " + std::to_string(Random::random_float(0.6, 1.0)) + ", " + std::to_string(Random::random_float(0.6, 1.0)) + ");");
					w_definitions.appendLine("    return mix(baseColor, waveColor, sin(6.28318 * t));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}

				// Define playful ripple-based texture function
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    float warp_x = sin(ray.p.x * " + ripple_freq_x + ") * " + distortion_x + ";");
				w_definitions.appendLine("    float warp_y = cos(ray.p.y * " + ripple_freq_y + ") * " + distortion_y + ";");
				w_definitions.appendLine("    ");
				w_definitions.appendLine("    float ripple_effect = abs(sin((ray.p.x + warp_x) * (ray.p.y + warp_y) * " + frequency_g + "));");
				w_definitions.appendLine("    vec3 color_variation = " + palette_name + "(ripple_effect);");
				w_definitions.appendLine("    return color_variation * (0.75 + " + amplitude_g + " * ripple_effect); ");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct StripesSphereTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{


				std::string texture_name = "texture_wave_" + std::to_string(index);



				std::string freq_u = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0 + 8.0);
				std::string freq_v = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0 + 8.0);


				std::string sharpness = std::to_string(Random::generate_random_float_0_to_1() * 0.8 + 0.2);


				std::string palette_name = "palette_generated_" + std::to_string(index);



				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.2, 0.5)) + ", "
						+ std::to_string(Random::random_float(0.2, 0.5)) + ", "
						+ std::to_string(Random::random_float(0.2, 0.5)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.5, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.5, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.5, 0.9)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}



				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Project normal onto two axes to get “u” and “v” coordinates");
				w_definitions.appendLine("    float u = dot(ray.normal, vec3(1.0, 0.0, 0.0));");
				w_definitions.appendLine("    float v = dot(ray.normal, vec3(0.0, 1.0, 0.0));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Create stripes: sinusoids around each axis");
				w_definitions.appendLine("    float stripe_u = abs(sin(u * " + freq_u + "));");
				w_definitions.appendLine("    float stripe_v = abs(sin(v * " + freq_v + "));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Combine them and sharpen the bands");
				w_definitions.appendLine("    float t = pow(stripe_u * stripe_v, " + sharpness + ");");
				w_definitions.appendLine("    t = clamp(t, 0.0, 1.0);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Lookup color from the palette");
				w_definitions.appendLine("    return " + palette_name + "(t);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct Checker3DSphereTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{

				// (fixed) Must keep this exact line:
				std::string texture_name = "texture_wave_" + std::to_string(index);



				std::string scale = std::to_string(Random::generate_random_float_0_to_1() * 5.0 + 3.0);


				std::string edge_smooth = std::to_string(Random::generate_random_float_0_to_1() * 0.1);


				std::string palette_name = "palette_generated_" + std::to_string(index);



				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.1, 0.3)) + ", "
						+ std::to_string(Random::random_float(0.1, 0.3)) + ", "
						+ std::to_string(Random::random_float(0.1, 0.3)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.7, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.7, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.7, 0.9)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}



				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Use world space position for a volumetric checker pattern");
				w_definitions.appendLine("    vec3 pos = ray.p / " + scale + ";");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Compute which cell we re in along each axis");
				w_definitions.appendLine("    float cx = floor(pos.x);");
				w_definitions.appendLine("    float cy = floor(pos.y);");
				w_definitions.appendLine("    float cz = floor(pos.z);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Checker value: sum of integer coordinates mod 2");
				w_definitions.appendLine("    float sum = mod(cx + cy + cz, 2.0);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Optionally smooth the edges by blending slightly near boundaries");
				w_definitions.appendLine("    vec3 local = fract(pos);");
				w_definitions.appendLine("    float fx = smoothstep(0.0, " + edge_smooth + ", local.x) * (1.0 - smoothstep(1.0 - " + edge_smooth + ", 1.0, local.x));");
				w_definitions.appendLine("    float fy = smoothstep(0.0, " + edge_smooth + ", local.y) * (1.0 - smoothstep(1.0 - " + edge_smooth + ", 1.0, local.y));");
				w_definitions.appendLine("    float fz = smoothstep(0.0, " + edge_smooth + ", local.z) * (1.0 - smoothstep(1.0 - " + edge_smooth + ", 1.0, local.z));");
				w_definitions.appendLine("    float blend = min(min(fx, fy), fz);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Final t value: near 0 if sum=0 (black), near 1 if sum=1 (white)");
				w_definitions.appendLine("    float t = mix(sum, 1.0 - sum, blend);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    return " + palette_name + "(t);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct AnimatedRingsTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{

				// (fixed) Must keep this exact line:
				std::string texture_name = "texture_wave_" + std::to_string(index);



				std::string base_freq = std::to_string(Random::generate_random_float_0_to_1() * 12.0 + 4.0);


				std::string speed = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 0.5);


				std::string ring_blur = std::to_string(Random::generate_random_float_0_to_1() * 0.2 + 0.05);

				// Palette name:
				std::string palette_name = "palette_generated_" + std::to_string(index);


				// (fixed structure) Palette function
				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.3, 0.6)) + ", "
						+ std::to_string(Random::random_float(0.3, 0.6)) + ", "
						+ std::to_string(Random::random_float(0.3, 0.6)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.4, 0.8)) + ", "
						+ std::to_string(Random::random_float(0.4, 0.8)) + ", "
						+ std::to_string(Random::random_float(0.4, 0.8)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}


				// (fixed) Texture signature:
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");

				w_definitions.appendLine("    float radius = length(ray.p.xz);");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float anim = radius * " + base_freq + " + ray.t * " + speed + ";");
				w_definitions.appendLine("");

				w_definitions.appendLine("    float f = abs(fract(anim) - 0.5);");
				w_definitions.appendLine("    float t = smoothstep(0.0, " + ring_blur + ", f);");
				w_definitions.appendLine("");

				w_definitions.appendLine("    return " + palette_name + "(t);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct BounceShiftTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{

				// (fixed) Must keep this exact line:
				std::string texture_name = "texture_wave_" + std::to_string(index);


				std::string paletteA_name = "palette_generatedA_" + std::to_string(index);
				std::string paletteB_name = "palette_generatedB_" + std::to_string(index);


				// (fixed structure) First palette
				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + paletteA_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.0, 0.3)) + ", "
						+ std::to_string(Random::random_float(0.0, 0.3)) + ", "
						+ std::to_string(Random::random_float(0.0, 0.3)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.7, 1.0)) + ", "
						+ std::to_string(Random::random_float(0.0, 0.3)) + ", "
						+ std::to_string(Random::random_float(0.0, 0.3)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}


				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + paletteB_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.3, 0.6)) + ", "
						+ std::to_string(Random::random_float(0.3, 0.6)) + ", "
						+ std::to_string(Random::random_float(0.3, 0.6)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.6, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.6, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.6, 0.9)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}


				// (fixed) Texture signature:
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");

				w_definitions.appendLine("    float t_coord = 0.0;");
				w_definitions.appendLine("    if (mod(float(ray.i), 2.0) < 1.0)");  // even bounces
				w_definitions.appendLine("    {");

				w_definitions.appendLine("        t_coord = fract(ray.p.y * 0.5 + 0.5);");
				w_definitions.appendLine("        return " + paletteA_name + "(t_coord);");
				w_definitions.appendLine("    }");
				w_definitions.appendLine("    else");  // odd bounces
				w_definitions.appendLine("    {");
				w_definitions.appendLine("        // Use surface normal’s z to drive the second palette");
				w_definitions.appendLine("        t_coord = abs(ray.normal.z);");
				w_definitions.appendLine("        return " + paletteB_name + "(t_coord);");
				w_definitions.appendLine("    }");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct WoodTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{
				std::string texture_name = "texture_wave_" + std::to_string(index);

				// Generate random frequencies similar to the example
				std::string frequency_x0 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0);
				std::string frequency_x1 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0);

				std::string frequency_y0 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0);
				std::string frequency_y1 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0);

				std::string frequency_z0 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0);
				std::string frequency_z1 = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 8.0);

				// Core wood parameters
				std::string wood_grain = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 50.0);
				std::string wood_density = std::to_string(Random::generate_random_float_0_to_1() * 0.5);

				std::string palette_name = "palette_wood_" + std::to_string(index);

				// Generate palette function (identical structure to example)
				{
					w_definitions.appendLine("");
					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3(" +
						std::to_string(Random::random_float(0.3, 0.5)) + ", " +
						std::to_string(Random::random_float(0.2, 0.3)) + ", " +
						std::to_string(Random::random_float(0.1, 0.2)) + ");");
					w_definitions.appendLine("    vec3 b = vec3(" +
						std::to_string(Random::random_float(0.4, 0.6)) + ", " +
						std::to_string(Random::random_float(0.3, 0.4)) + ", " +
						std::to_string(Random::random_float(0.2, 0.3)) + ");");
					w_definitions.appendLine("    vec3 c = vec3(" +
						std::to_string(Random::generate_random_float_0_to_1()) + ", " +
						std::to_string(Random::generate_random_float_0_to_1()) + ", " +
						std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3(" +
						std::to_string(Random::generate_random_float_0_to_1()) + ", " +
						std::to_string(Random::generate_random_float_0_to_1()) + ", " +
						std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}

				// Generate texture function (identical structure to example)
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    ");
				w_definitions.appendLine("    float d0 = dot(vec3(1.0, 0.0, 0.0), ray.normal);");
				w_definitions.appendLine("    float d1 = dot(vec3(0.0, 1.0, 0.0), ray.normal);");
				w_definitions.appendLine("    float d2 = dot(vec3(0.0, 0.0, 1.0), ray.normal);");
				w_definitions.appendLine("    ");
				w_definitions.appendLine("    float x_grain = min(1.0, pow(abs(sin(ray.p.y * " + frequency_x0 + ")) * abs(sin(ray.p.z * " + frequency_x1 + ")), 0.5));");
				w_definitions.appendLine("    float y_grain = min(1.0, pow(abs(sin(ray.p.x * " + frequency_y0 + ")) * abs(sin(ray.p.z * " + frequency_y1 + ")), 0.5));");
				w_definitions.appendLine("    float z_grain = min(1.0, pow(abs(sin(ray.p.x * " + frequency_z0 + ")) * abs(sin(ray.p.y * " + frequency_z1 + ")), 0.5));");
				w_definitions.appendLine("    ");
				w_definitions.appendLine("    vec3 v0 = " + palette_name + "(sin((d0 * x_grain * d1 * y_grain * d2 * z_grain) * " + wood_grain + ")); ");
				w_definitions.appendLine("    vec3 v1 = " + palette_name + "((d0 * x_grain + d1 * y_grain + d2 * z_grain) * (1.0 / 3.0));");
				w_definitions.appendLine("    return v1 * (0.75 + " + wood_density + " * v0);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct HighFreqTriplanarTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{

				// (fixed) Must keep this exact line:
				std::string texture_name = "texture_wave_" + std::to_string(index);


				// (variable) High-frequency multipliers for each plane
				std::string freqXY = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 60.0 + 40.0);
				std::string freqYZ = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 60.0 + 40.0);
				std::string freqXZ = std::to_string(Random::generate_random_float_minus_one_to_plus_one() * 60.0 + 40.0);

				// (variable) Slight amplitude perturbation
				std::string ampVariation = std::to_string(Random::generate_random_float_0_to_1() * 0.3 + 0.7);

				// Palette function name
				std::string palette_name = "palette_generated_" + std::to_string(index);


				// (fixed structure) Palette function
				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.2, 0.5)) + ", "
						+ std::to_string(Random::random_float(0.2, 0.5)) + ", "
						+ std::to_string(Random::random_float(0.2, 0.5)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.6, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.6, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.6, 0.9)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}


				// (fixed) Texture signature:
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Triplanar blending weights based on absolute normal");
				w_definitions.appendLine("    vec3 n = abs(ray.normal);");
				w_definitions.appendLine("    float sum = n.x + n.y + n.z;");
				w_definitions.appendLine("    vec3 w = n / sum;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Sample each plane with very high-frequency sine patterns");
				w_definitions.appendLine("    // XY plane uses XY coordinates of position");
				w_definitions.appendLine("    float sampleXY = abs(sin(ray.p.x * " + freqXY + ") * sin(ray.p.y * " + freqXY + "));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // YZ plane uses YZ coordinates");
				w_definitions.appendLine("    float sampleYZ = abs(sin(ray.p.y * " + freqYZ + ") * sin(ray.p.z * " + freqYZ + "));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // XZ plane uses XZ coordinates");
				w_definitions.appendLine("    float sampleXZ = abs(sin(ray.p.x * " + freqXZ + ") * sin(ray.p.z * " + freqXZ + "));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Combine samples by blending weights");
				w_definitions.appendLine("    float t = w.x * sampleYZ + w.y * sampleXZ + w.z * sampleXY;");
				w_definitions.appendLine("    t = fract(t * " + ampVariation + ");");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Lookup color from the generated palette");
				w_definitions.appendLine("    return " + palette_name + "(t);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct VoronoiTriplanarTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{
				// (fixed) Must keep this exact line:
				std::string texture_name = "texture_wave_" + std::to_string(index);

				// (variable) Base frequency for cell size
				std::string cellFreq = std::to_string((Random::generate_random_float_0_to_1() * 0.2 + 0.2) * 0.02);

				// (variable) Distortion factor to jitter cell boundaries
				std::string jitter = std::to_string((Random::generate_random_float_0_to_1() * 0.2 + 0.02) * 0.02);

				// Palette function name
				std::string palette_name = "palette_generated_" + std::to_string(index);

				// (fixed structure) Palette function
				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.0, 0.3)) + ", "
						+ std::to_string(Random::random_float(0.0, 0.3)) + ", "
						+ std::to_string(Random::random_float(0.0, 0.3)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.6, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.6, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.6, 0.9)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}


				// (fixed) Texture signature:
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Triplanar weights from normal");
				w_definitions.appendLine("    vec3 n = abs(ray.normal);");
				w_definitions.appendLine("    float sum = n.x + n.y + n.z;");
				w_definitions.appendLine("    vec3 w = n / sum;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Function to emulate a single cell value via jittered dot:");
				w_definitions.appendLine("    #define CELL(p, f, j) fract(sin(dot(p, vec2(12.9898 + j, 78.233 + j)) * f) * 43758.5453)");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Sample XY plane:");
				w_definitions.appendLine("    vec2 coordXY = ray.p.xy * " + cellFreq + ";");
				w_definitions.appendLine("    float baseXY = floor(coordXY.x) + floor(coordXY.y);");
				w_definitions.appendLine("    float jitterXY = CELL(fract(coordXY), " + cellFreq + ", 1.0 + (" + jitter + "));");
				w_definitions.appendLine("    float sampleXY = fract(baseXY + jitterXY);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Sample YZ plane:");
				w_definitions.appendLine("    vec2 coordYZ = ray.p.yz * " + cellFreq + ";");
				w_definitions.appendLine("    float baseYZ = floor(coordYZ.x) + floor(coordYZ.y);");
				w_definitions.appendLine("    float jitterYZ = CELL(fract(coordYZ), " + cellFreq + ", 2.0 + (" + jitter + "));");
				w_definitions.appendLine("    float sampleYZ = fract(baseYZ + jitterYZ);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Sample XZ plane:");
				w_definitions.appendLine("    vec2 coordXZ = ray.p.xz * " + cellFreq + ";");
				w_definitions.appendLine("    float baseXZ = floor(coordXZ.x) + floor(coordXZ.y);");
				w_definitions.appendLine("    float jitterXZ = CELL(fract(coordXZ), " + cellFreq + ", 3.0 + (" + jitter + "));");
				w_definitions.appendLine("    float sampleXZ = fract(baseXZ + jitterXZ);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Blend by weights and remap into [0,1]");
				w_definitions.appendLine("    float t = w.x * sampleXY + w.y * sampleYZ + w.z * sampleXZ;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Lookup color from palette");
				w_definitions.appendLine("    return " + palette_name + "(t);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct CrackledGlazeTriplanarTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{

				// (fixed) Must keep this exact line:
				std::string texture_name = "texture_wave_" + std::to_string(index);


				// (variable) Base crackle frequency (very high)
				std::string crackFreq = std::to_string(Random::generate_random_float_0_to_1() * 80.0 + 60.0);

				// (variable) Crack vein thickness control
				std::string veinThickness = std::to_string(Random::generate_random_float_0_to_1() * 0.04 + 0.01);

				// Palette function name
				std::string palette_name = "palette_generated_" + std::to_string(index);


				// (fixed structure) Palette function
				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.1, 0.4)) + ", "
						+ std::to_string(Random::random_float(0.1, 0.4)) + ", "
						+ std::to_string(Random::random_float(0.1, 0.4)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.5, 0.8)) + ", "
						+ std::to_string(Random::random_float(0.5, 0.8)) + ", "
						+ std::to_string(Random::random_float(0.5, 0.8)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}


				// (fixed) Texture signature:
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Triplanar blending weights");
				w_definitions.appendLine("    vec3 n = abs(ray.normal);");
				w_definitions.appendLine("    float sum = n.x + n.y + n.z;");
				w_definitions.appendLine("    vec3 w = n / sum;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Crackle pattern per plane: high frequency sine, thresholded");
				w_definitions.appendLine("    // XY plane crackle:");
				w_definitions.appendLine("    float cXY = sin(ray.p.x * " + crackFreq + ") * sin(ray.p.y * " + crackFreq + ");");
				w_definitions.appendLine("    float edgeXY = smoothstep(" + veinThickness + ", "
					+ std::to_string(atof(veinThickness.c_str()) * 1.5)
					+ ", abs(cXY));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // YZ plane crackle:");
				w_definitions.appendLine("    float cYZ = sin(ray.p.y * " + crackFreq + ") * sin(ray.p.z * " + crackFreq + ");");
				w_definitions.appendLine("    float edgeYZ = smoothstep(" + veinThickness + ", "
					+ std::to_string(atof(veinThickness.c_str()) * 1.5)
					+ ", abs(cYZ));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // XZ plane crackle:");
				w_definitions.appendLine("    float cXZ = sin(ray.p.x * " + crackFreq + ") * sin(ray.p.z * " + crackFreq + ");");
				w_definitions.appendLine("    float edgeXZ = smoothstep(" + veinThickness + ", "
					+ std::to_string(atof(veinThickness.c_str()) * 1.5)
					+ ", abs(cXZ));");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Combine by weight and invert so cracks appear dark on bright glaze");
				w_definitions.appendLine("    float t = 1.0 - (w.x * edgeXY + w.y * edgeYZ + w.z * edgeXZ);");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Lookup color from palette");
				w_definitions.appendLine("    return " + palette_name + "(t);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};

		struct FractalMarbleTriplanarTexture
		{
			static void generate_texture(Writer& w_definitions, int index)
			{

				// (fixed) Must keep this exact line:
				std::string texture_name = "texture_wave_" + std::to_string(index);


				// (variable) Initial frequency
				std::string baseFreq = std::to_string(Random::generate_random_float_0_to_1() * 30.0 + 20.0);

				// (variable) Number of octaves for fractal
				int octaves = 4;

				// (variable) Lacunarity (frequency multiplier per octave)
				std::string lacunarity = std::to_string(Random::generate_random_float_0_to_1() * 2.0 + 1.5);

				// (variable) Gain (amplitude falloff per octave)
				std::string gain = std::to_string(Random::generate_random_float_0_to_1() * 0.5 + 0.4);

				// Palette function name
				std::string palette_name = "palette_generated_" + std::to_string(index);


				// (fixed structure) Palette function
				{
					w_definitions.appendLine("");

					w_definitions.appendLine("vec3 " + palette_name + "(float t)");
					w_definitions.appendLine("{");
					w_definitions.appendLine("    vec3 a = vec3("
						+ std::to_string(Random::random_float(0.2, 0.5)) + ", "
						+ std::to_string(Random::random_float(0.2, 0.5)) + ", "
						+ std::to_string(Random::random_float(0.2, 0.5)) + ");");
					w_definitions.appendLine("    vec3 b = vec3("
						+ std::to_string(Random::random_float(0.5, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.5, 0.9)) + ", "
						+ std::to_string(Random::random_float(0.5, 0.9)) + ");");
					w_definitions.appendLine("    vec3 c = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    vec3 d = vec3("
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ", "
						+ std::to_string(Random::generate_random_float_0_to_1()) + ");");
					w_definitions.appendLine("    ");
					w_definitions.appendLine("    return a + b * cos(6.28318 * (c * t + d));");
					w_definitions.appendLine("}");
					w_definitions.appendLine("");
				}


				// (fixed) Texture signature:
				w_definitions.appendLine("");
				w_definitions.appendLine("vec3 " + texture_name + "(Ray ray)");
				w_definitions.appendLine("{");
				w_definitions.appendLine("    // Triplanar weights from normal");
				w_definitions.appendLine("    vec3 n = abs(ray.normal);");
				w_definitions.appendLine("    float sum = n.x + n.y + n.z;");
				w_definitions.appendLine("    vec3 w = n / sum;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Fractal noise approximation using multiple sine octaves per plane");
				w_definitions.appendLine("    float noiseXY = 0.0;");
				w_definitions.appendLine("    float noiseYZ = 0.0;");
				w_definitions.appendLine("    float noiseXZ = 0.0;");
				w_definitions.appendLine("    float amplitude = 1.0;");
				w_definitions.appendLine("    float frequency = " + baseFreq + ";");
				w_definitions.appendLine("");
				w_definitions.appendLine("    for (int o = 0; o < " + std::to_string(octaves) + "; ++o)");
				w_definitions.appendLine("    {");
				w_definitions.appendLine("        // Sample sine-based “noise” on each plane");
				w_definitions.appendLine("        noiseXY += amplitude * abs(sin((ray.p.x + ray.p.y) * frequency));");
				w_definitions.appendLine("        noiseYZ += amplitude * abs(sin((ray.p.y + ray.p.z) * frequency));");
				w_definitions.appendLine("        noiseXZ += amplitude * abs(sin((ray.p.x + ray.p.z) * frequency));");
				w_definitions.appendLine("");
				w_definitions.appendLine("        frequency *= " + lacunarity + ";");
				w_definitions.appendLine("        amplitude *= " + gain + ";");
				w_definitions.appendLine("    }");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Normalize by sum of amplitudes: 1 + gain + gain^2 + …");
				w_definitions.appendLine("    float normFactor = 0.0;");
				w_definitions.appendLine("    float ampAcc = 1.0;");
				w_definitions.appendLine("    for (int i = 0; i < " + std::to_string(octaves) + "; ++i) { normFactor += ampAcc; ampAcc *= " + gain + "; }");
				w_definitions.appendLine("    noiseXY /= normFactor;");
				w_definitions.appendLine("    noiseYZ /= normFactor;");
				w_definitions.appendLine("    noiseXZ /= normFactor;");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Combine fractal values by triplanar weights");
				w_definitions.appendLine("    float t = w.x * noiseYZ + w.y * noiseXZ + w.z * noiseXY;");
				w_definitions.appendLine("    t = fract(t * 1.2);  // extra wobble");
				w_definitions.appendLine("");
				w_definitions.appendLine("    // Lookup color from palette");
				w_definitions.appendLine("    return " + palette_name + "(t);");
				w_definitions.appendLine("}");
				w_definitions.appendLine("");
			}
		};


		{
			std::vector<std::function<void(Writer& w_definitions, int index)>> function_vector;
			function_vector.push_back(WaveSphereTexture::generate_texture);
			function_vector.push_back(WarpedRippleTexture::generate_texture);
			function_vector.push_back(StripesSphereTexture::generate_texture);
			function_vector.push_back(Checker3DSphereTexture::generate_texture);
			function_vector.push_back(AnimatedRingsTexture::generate_texture);
			function_vector.push_back(BounceShiftTexture::generate_texture);
			function_vector.push_back(WoodTexture::generate_texture);
			function_vector.push_back(HighFreqTriplanarTexture::generate_texture);
			function_vector.push_back(VoronoiTriplanarTexture::generate_texture);
			function_vector.push_back(CrackledGlazeTriplanarTexture::generate_texture);
			function_vector.push_back(FractalMarbleTriplanarTexture::generate_texture);

			auto el_0 = Random::random_element(function_vector);
			auto el_1 = Random::random_element(function_vector);
			auto el_2 = Random::random_element(function_vector);
			auto el_3 = Random::random_element(function_vector);

			el_0(w_definitons, 0);
			el_1(w_definitons, 1);
			el_2(w_definitons, 2);
			el_3(w_definitons, 3);

			struct TextureCompositions
			{
				static void composition_0000(Writer& writer)
				{
					writer.appendLine("	return abs(2.0 * sin((texture_wave_0(ray) * texture_wave_1(ray) +  texture_wave_2(ray) * texture_wave_3(ray))));");
				}

				static void composition_0001(Writer& writer)
				{
					writer.appendLine("	return fract((texture_wave_0(ray) * texture_wave_1(ray) *  texture_wave_2(ray) * texture_wave_3(ray))) * 2.0;");
				}

				static void composition_0002(Writer& writer)
				{
					writer.appendLine("	return (texture_wave_0(ray) * 0.25 + texture_wave_1(ray) * 0.25 + texture_wave_2(ray) * 0.25 + texture_wave_3(ray) * 0.25) * 2.0;");
				}

				static void composition_0003(Writer& writer)
				{
					writer.appendLine("	return (texture_wave_0(ray) * 0.25 + texture_wave_1(ray) * sin(0.25 + texture_wave_2(ray) * 0.25 + texture_wave_3(ray) * 0.25)) * 0.2;");
				}

				// Blend using sin(time) modulation and multiply with texture_wave_2, add texture_wave_3
				static void composition_0004(Writer& writer)
				{
					writer.appendLine(
						"\treturn sin(texture_wave_0(ray) + cos(texture_wave_1(ray) * time)) "
						"* texture_wave_2(ray) + texture_wave_3(ray);"
					);
				}

				// Mix between wave_0 and wave_1 based on a smoothstep of ray.t + time, then multiply by wave_2 and add attenuated wave_3
				static void composition_0005(Writer& writer)
				{
					writer.appendLine(
						"\treturn mix(texture_wave_0(ray), texture_wave_1(ray), "
						"smoothstep(0.0, 1.0, sin(ray.t * 0.1 + time))) "
						"* texture_wave_2(ray) + texture_wave_3(ray) * 0.2;"
					);
				}

				// Use ray.normal to modulate the difference between wave_2 and wave_3, then add wave_0 and wave_1
				static void composition_0006(Writer& writer)
				{
					writer.appendLine(
						"\tfloat Ndot = abs(dot(ray.normal, vec3(1.0, 1.0, 1.0)));"
						" return texture_wave_0(ray) + texture_wave_1(ray) + "
						"(texture_wave_2(ray) - texture_wave_3(ray)) * Ndot;"
					);
				}

				// Use fract of ray.p components to blend wave_0 and wave_2, plus a product of wave_1 and wave_3
				static void composition_0007(Writer& writer)
				{
					writer.appendLine(
						"\tfloat f = pow(fract(ray.p.x + ray.p.y + ray.p.z), 2.0);"
						" return mix(texture_wave_0(ray), texture_wave_2(ray), f) "
						"+ texture_wave_1(ray) * texture_wave_3(ray);"
					);
				}

				// Alternate between pairs of waves based on ray.i parity, then average and modulate by sin(time)
				static void composition_0008(Writer& writer)
				{
					writer.appendLine(
						"\tvec3 a = (ray.i % 2 != 0) ? texture_wave_0(ray) : texture_wave_1(ray);"
						" vec3 b = (ray.i % 3 != 0) ? texture_wave_2(ray) : texture_wave_3(ray);"
						" return mix(a, b, 0.5) * vec3(sin(time));"
					);
				}

				// Swirl coordinates via sin(ray.p + time) per component, blend wave_1, and add wave_3
				static void composition_0009(Writer& writer)
				{
					writer.appendLine(
						"\tvec3 swirl = vec3(sin(ray.p.x + time), sin(ray.p.y + time), sin(ray.p.z + time));"
						" return texture_wave_0(ray) * 0.5 + texture_wave_1(ray) * swirl + texture_wave_3(ray) * 0.1;"
					);
				}

				// Raise wave_0 to the power of (wave_1 + 1), multiply by wave_2, and add wave_3 attenuated
				static void composition_0010(Writer& writer)
				{
					writer.appendLine(
						"\tvec3 base = texture_wave_0(ray) * 0.5 + vec3(0.5);"
						" vec3 exponent = texture_wave_1(ray) + vec3(1.0);"
						" return pow(base, exponent) * texture_wave_2(ray) + texture_wave_3(ray) * 0.1;"
					);
				}

				// Blend based on length of ray.normal, add sin(ray.t) * wave_2 and cos(ray.t) * wave_3
				static void composition_0011(Writer& writer)
				{
					writer.appendLine(
						"\tfloat Ln = length(ray.normal);"
						" return texture_wave_0(ray) * Ln + texture_wave_1(ray) * (1.0 - Ln) "
						"+ texture_wave_2(ray) * sin(ray.t) + texture_wave_3(ray) * cos(ray.t);"
					);
				}

				// Cross ray.normal with a fixed axis, clamp to [0,1], multiply by wave_0, then add wave_1 and wave_3
				static void composition_0012(Writer& writer)
				{
					writer.appendLine(
						"\tvec3 c = clamp(cross(ray.normal, vec3(1.0, 0.0, 0.0)), 0.0, 1.0);"
						" return texture_wave_0(ray) * c + texture_wave_1(ray) * 0.2 + texture_wave_3(ray) * 0.3;"
					);
				}

				// Use fract on wave_0 and wave_1 plus sin(time), then combine with wave_2, wave_3, and ray.t
				static void composition_0013(Writer& writer)
				{
					writer.appendLine(
						"\tvec3 f0 = fract(texture_wave_0(ray) * 3.0 + sin(time));"
						" vec3 f1 = fract(texture_wave_1(ray) * 2.0 + cos(time));"
						" return vec3(f0.r, f1.g, fract((texture_wave_2(ray) * texture_wave_3(ray)).r + ray.t * 0.1));"
					);
				}

				// Smoothstep based blend between wave_0 and wave_3 based on wave_1.r * wave_2.g
				static void composition_0014(Writer& writer)
				{
					writer.appendLine(
						"\tfloat blendVal = smoothstep(0.0, 1.0, texture_wave_1(ray).r * texture_wave_2(ray).g);"
						" return mix(texture_wave_0(ray), texture_wave_3(ray), blendVal);"
					);
				}

				// Use dot between wave_0 and wave_1 to generate a sin-based mask, multiply by wave_2, and add wave_3
				static void composition_0015(Writer& writer)
				{
					writer.appendLine(
						"\tfloat d = dot(texture_wave_0(ray), texture_wave_1(ray));"
						" vec3 mask = vec3(sin(d + time));"
						" return texture_wave_2(ray) * mask + texture_wave_3(ray) * 0.3;"
					);
				}

				// Distance-based mix between wave_0 and wave_2 over the XY plane, modulated by sin(time)
				static void composition_0016(Writer& writer)
				{
					writer.appendLine(
						"\tfloat dist = distance(ray.p.xy, vec2(0.5));"
						" float m = smoothstep(0.0, 1.0, dist + sin(time * 0.5));"
						" return mix(texture_wave_0(ray), texture_wave_2(ray), m) + texture_wave_3(ray) * 0.05 + texture_wave_1(ray) * 0.02;"
					);
				}

				// Combine a rotating sample of wave_1 using cos(ray.i) and sin(ray.i), modulate with wave_0, add wave_2 and wave_3
				static void composition_0017(Writer& writer)
				{
					writer.appendLine(
						"\tvec2 rot = vec2(cos(float(ray.i)), sin(float(ray.i)));"
						" vec3 s = texture_wave_1(ray) * vec3(rot, 1.0);"
						" return texture_wave_0(ray) * 0.4 + s * 0.6 + texture_wave_2(ray) * 0.1 + texture_wave_3(ray) * 0.1;"
					);
				}

				// Use pow on distance of ray.p to create a vignette effect, then blend all four waves
				static void composition_0018(Writer& writer)
				{
					writer.appendLine(
						"\tfloat v = pow(distance(ray.p.xy, vec2(0.5)), 2.0);"
						" vec3 blend01 = mix(texture_wave_0(ray), texture_wave_1(ray), v);"
						" vec3 blend23 = mix(texture_wave_2(ray), texture_wave_3(ray), 1.0 - v);"
						" return mix(blend01, blend23, 0.5);"
					);
				}

				// Use a rotating normal-based mask to combine wave_0 and wave_3, then add a low-frequency wave from wave_2
				static void composition_0019(Writer& writer)
				{
					writer.appendLine(
						"\tvec3 normMask = abs(normalize(ray.normal));"
						" vec3 combo = mix(texture_wave_0(ray), texture_wave_3(ray), normMask);"
						" return combo * 0.7 + texture_wave_2(ray) * 0.3 * sin(time * 0.2) + texture_wave_1(ray) * 0.01;"
					);
				}

				// High-frequency detail by taking the fract of wave_0 * 10, then modulating with wave_1 and adding wave_3
				static void composition_0020(Writer& writer)
				{
					writer.appendLine(
						"\tvec3 detail = fract(texture_wave_0(ray) * 10.0);"
						" return detail * texture_wave_1(ray) + texture_wave_3(ray) * 0.2 + texture_wave_2(ray) * 0.1;"
					);
				}

				// Swirling vortex with time-based distortion
				static void composition_0021(Writer& writer)
				{
					writer.appendLine("	vec3 spiral = 0.5 + 0.5 * cos(6.28318 * (texture_wave_3(ray).yzx * 0.2 + texture_wave_0(ray).yzx + time + ray.p.x));");
					writer.appendLine("	return mix(texture_wave_1(ray), texture_wave_2(ray), spiral) * abs(sin(time));");
				}

				static void composition_0022(Writer& writer)
				{
					writer.appendLine("	return abs(texture_wave_0(ray) * texture_wave_1(ray) - texture_wave_2(ray) * texture_wave_3(ray)) * 4.0;");
				}

				// Normal-based energy flow
				static void composition_0023(Writer& writer)
				{
					writer.appendLine("	vec3 energy = pow(abs(ray.normal), vec3(3.0));");
					writer.appendLine("	return energy * mix(texture_wave_0(ray), texture_wave_1(ray).gbr, texture_wave_2(ray).brg) + texture_wave_0(ray) * 0.02;");
				}

				// Distance-based texture fading
				static void composition_0024(Writer& writer)
				{
					writer.appendLine("	float fade = exp(-0.1 * ray.t);");
					writer.appendLine("	vec3 deep = texture_wave_3(ray) * sin(ray.t * 0.5) + (texture_wave_1(ray) * texture_wave_2(ray)) * 0.047;");
					writer.appendLine("	return fade * texture_wave_0(ray) + (1.0 - fade) * deep;");
				}

				// Refraction simulation
				static void composition_0025(Writer& writer)
				{
					writer.appendLine("	vec2 refOffset = 0.1 * texture_wave_2(ray).xy * sin(time);");
					writer.appendLine("	Ray refracted = ray;");
					writer.appendLine("	refracted.p.xy += refOffset;");
					writer.appendLine("	return mix(texture_wave_1(refracted), texture_wave_3(ray), 0.7);");
				}

				// Iteration-based psychedelic effect
				static void composition_0026(Writer& writer)
				{
					writer.appendLine("	float iterWave = sin(float(ray.i) * 0.4 + time * 0.027);");
					writer.appendLine("	return abs((iterWave * (texture_wave_0(ray) *( texture_wave_3(ray) + texture_wave_2(ray)) * 0.47  + (1.0 - iterWave) * texture_wave_1(ray))));");
				}

				// Position-based frequency modulation
				static void composition_0027(Writer& writer)
				{
					writer.appendLine("	vec3 posFreq = sin(ray.p * 5.0 + time);");
					writer.appendLine("	return abs(posFreq * (texture_wave_0(ray) + texture_wave_1(ray)) + (1.0 - posFreq) * (texture_wave_2(ray) * texture_wave_2(ray))) * 2.0;");
				}

				// Tri-planar projection with normal mapping
				static void composition_0028(Writer& writer)
				{
					writer.appendLine("	vec3 weights = abs(normalize(ray.normal));");
					writer.appendLine("	weights /= weights.x + weights.y + weights.z;");
					writer.appendLine("	return 0.2 + 0.7 * sin(time * 0.02 + (weights.x * texture_wave_0(ray) + weights.y * texture_wave_1(ray) + weights.z * texture_wave_2(ray)) / texture_wave_3(ray));");
				}

				// Harmonic resonance pattern
				static void composition_0029(Writer& writer)
				{
					writer.appendLine("	vec3 base_0 = texture_wave_0(ray) * texture_wave_1(ray);");
					writer.appendLine("	vec3 base_1 = texture_wave_2(ray) * texture_wave_3(ray);");
					writer.appendLine("	vec3 harmonic = sin(50.0 * cross(base_0, base_1) + 0.02 * time);");
					writer.appendLine("	return clamp((sin(base_0) / cos(base_1)) * harmonic * 3.0, 0.0, 1.0) * 4.7;");
				}

				// Animated texture warping
				static void composition_0030(Writer& writer)
				{
					writer.appendLine("	vec2 warpUV = 0.1 * vec2(sin(time * 0.02), cos(time * 0.017));");
					writer.appendLine("	Ray warped = ray;");
					writer.appendLine("	warped.p.xy += warpUV * texture_wave_3(ray).xy;");
					writer.appendLine("	return pow(mix(texture_wave_1(warped), texture_wave_2(ray), 0.8), vec3(2.0 + sin(ray.p.x), 2.0 + cos(ray.p.y), 2.0 + sin(ray.p.z)));");
				}

				// Depth-aware texture blending
				static void composition_0031(Writer& writer)
				{
					writer.appendLine("	float depthFactor = smoothstep(0.0, 20.0, ray.t);");
					writer.appendLine("	vec3 shallow = texture_wave_0(ray) * texture_wave_1(ray);");
					writer.appendLine("	vec3 deep = texture_wave_2(ray) * texture_wave_3(ray);");
					writer.appendLine("	return mix(shallow, deep, depthFactor);");
				}

				// Glowing edge detection
				static void composition_0032(Writer& writer)
				{
					writer.appendLine("	vec3 diff = abs(texture_wave_0(ray) - texture_wave_1(ray));");
					writer.appendLine("	float edge = length(diff) > 0.3 ? 1.0 : 0.0;");
					writer.appendLine("	return edge * (texture_wave_2(ray) + sin(time * 0.1 + ray.p.x * 2.0)) + (1.0 - edge) * texture_wave_3(ray);");
				}

				// Temporal texture accumulation
				static void composition_0033(Writer& writer)
				{
					writer.appendLine("	float phase = fract(time * 0.2);");
					writer.appendLine("	return phase * texture_wave_0(ray) + (1.0 - phase) * texture_wave_3(ray);");
				}

				// Normal-driven texture switching
				static void composition_0034(Writer& writer)
				{
					writer.appendLine("	float selector = dot(ray.normal, vec3(0,1,0));");
					writer.appendLine("	return selector > 0.5 ? texture_wave_0(ray) * texture_wave_1(ray) : texture_wave_2(ray) * texture_wave_3(ray);");
				}

				// Quadratic texture interaction
				static void composition_0035(Writer& writer)
				{
					writer.appendLine("	vec3 a = texture_wave_0(ray);");
					writer.appendLine("	vec3 b = texture_wave_1(ray);");
					writer.appendLine("	return a*a + 2.0*a*b + b*b;");
				}

				// Polar coordinate distortion
				static void composition_0036(Writer& writer)
				{
					writer.appendLine("	float r = length(ray.p.xy);");
					writer.appendLine("	float theta = atan(ray.p.y, ray.p.x) + time * 0.002;");
					writer.appendLine("	vec2 polarUV = vec2(r * cos(theta), r * sin(theta));");
					writer.appendLine("	Ray polarRay = ray;");
					writer.appendLine("	polarRay.p.xy = polarUV;");
					writer.appendLine("	return (texture_wave_2(polarRay) * (0.5 + 0.5 * sin(r * 10.0 - time * 0.002))) * 0.27;");
				}

				// Texture feedback loop
				static void composition_0037(Writer& writer)
				{
					writer.appendLine("	vec3 fb = texture_wave_0(ray);");
					writer.appendLine("	for(int i=0; i<3; i++) {");
					writer.appendLine("		fb = 0.9 * (fb + 0.2 * texture_wave_1(ray));");
					writer.appendLine("	}");
					writer.appendLine("	return fb;");
				}

				// Position-based texture masking
				static void composition_0038(Writer& writer)
				{
					writer.appendLine("	vec3 grid = step(0.95, fract(ray.p * 2.0));");
					writer.appendLine("	float mask = clamp(grid.x + grid.y + grid.z, 0.0, 1.0);");
					writer.appendLine("	return mask * texture_wave_3(ray) + (1.0 - mask) * texture_wave_0(ray);");
				}

				// Multi-frequency texture synthesis
				static void composition_0039(Writer& writer)
				{
					writer.appendLine("	vec3 lowFreq = texture_wave_0(ray) * texture_wave_1(ray);");
					writer.appendLine("	vec3 hiFreq = sin(50.0 * texture_wave_2(ray)) * texture_wave_3(ray);");
					writer.appendLine("	return lowFreq * (1.0 - hiFreq) + hiFreq;");
				}

				// Physically-inspired light model
				static void composition_0040(Writer& writer)
				{
					writer.appendLine("	vec3 diffuse = texture_wave_0(ray) * max(0.0, dot(ray.normal, vec3(0,1,0)));");
					writer.appendLine("	vec3 specular = texture_wave_1(ray) * pow(max(0.0, dot(reflect(-vec3(0,1,0), ray.normal), ray.normal)), 32.0);");
					writer.appendLine("	return diffuse * texture_wave_2(ray) + specular * texture_wave_3(ray);");
				}



				// Helper to avoid retyping texture fetches constantly in GLSL
				static void prependTextureFetches(Writer& writer) {
					writer.appendLine("	vec3 t0 = texture_wave_0(ray);");
					writer.appendLine("	vec3 t1 = texture_wave_1(ray);");
					writer.appendLine("	vec3 t2 = texture_wave_2(ray);");
					writer.appendLine("	vec3 t3 = texture_wave_3(ray);");
				}

				// --- Simple Arithmetic & Blending ---

				static void composition_0041_WeightedSumTime(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	float w0 = 0.5 + 0.5 * sin(time * 0.5);");
					writer.appendLine("	float w1 = 0.5 + 0.5 * cos(time * 0.3);");
					writer.appendLine("	float w2 = fract(time * 0.2);");
					writer.appendLine("	float w3 = 1.0 - w0 - w1 - w2; // Ensure sum can be normalized or clamped");
					writer.appendLine("	return clamp(t0*w0 + t1*w1 + t2*w2 + t3*abs(w3), vec3(0.0), vec3(1.0));");
				}

				static void composition_0042_MultiplyAndLerp(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	vec3 prod1 = t0 * t1;");
					writer.appendLine("	vec3 prod2 = t2 * t3;");
					writer.appendLine("	float mixFactor = smoothstep(0.0, 1.0, (sin(time) + 1.0) * 0.5);");
					writer.appendLine("	return mix(prod1, prod2, mixFactor);");
				}

				// --- Using Ray Properties ---

				static void composition_0043_RayDistanceBlend(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	float distFactor = clamp(ray.t / 10.0, 0.0, 1.0); // Blend over 10 units of distance");
					writer.appendLine("	vec3 nearColor = mix(t0, t1, 0.5 + 0.5 * sin(ray.p.x * 0.5));");
					writer.appendLine("	vec3 farColor  = mix(t2, t3, 0.5 + 0.5 * cos(ray.p.y * 0.5));");
					writer.appendLine("	return mix(nearColor, farColor, smoothstep(0.0, 1.0, distFactor));");
				}

				static void composition_0044_RayNormalModulation(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	float upFactor = max(0.0, dot(ray.normal, vec3(0,1,0))); // How much normal points up");
					writer.appendLine("	float sideFactor = abs(dot(ray.normal, vec3(1,0,0))); // How much normal points sideways");
					writer.appendLine("	vec3 mix1 = mix(t0, t1, upFactor);");
					writer.appendLine("	vec3 mix2 = mix(t2, t3, sideFactor);");
					writer.appendLine("	return mix(mix1, mix2, fract(time * 0.1 + ray.p.z * 0.1));");
				}

				static void composition_0045_RayIterationPattern(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	float iterNorm = float(ray.i % 4) / 3.0; // Normalized iteration [0,1] over 4 iterations");
					writer.appendLine("	if (ray.i % 4 == 0) return t0 * (0.5 + 0.5 * sin(time + ray.p.x));");
					writer.appendLine("	if (ray.i % 4 == 1) return t1 * (0.5 + 0.5 * cos(time + ray.p.y));");
					writer.appendLine("	if (ray.i % 4 == 2) return t2 * (0.5 + 0.5 * sin(time * 0.5 + ray.p.z));");
					writer.appendLine("	return t3 * (0.5 + 0.5 * cos(time * 0.5 + ray.p.x + ray.p.y));");
				}

				static void composition_0046_RayPositionFractal(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	float pattern = fract(sin(dot(ray.p.xy, vec2(12.9898, 78.233))) * 43758.5453);");
					writer.appendLine("	vec3 c1 = mix(t0, t1, pattern);");
					writer.appendLine("	vec3 c2 = mix(t2, t3, fract(pattern * 1.5));");
					writer.appendLine("	return mix(c1, c2, smoothstep(0.3, 0.7, sin(time + ray.p.z * 0.2)));");
				}

				// --- Trigonometric & Periodic ---

				static void composition_0047_SinCosPowerMix(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	vec3 s = sin(t0 * 3.14159 + time);");
					writer.appendLine("	vec3 c = cos(t1 * 2.0 + time * 0.5);");
					writer.appendLine("	vec3 p = pow(abs(t2), vec3(1.5 + sin(time * 0.2)));");
					writer.appendLine("	return mix(s * c, p + t3, clamp(length(t0-t1), 0.0, 1.0));");
				}

				static void composition_0048_LayeredWaves(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	vec3 wave1 = t0 * (0.5 + 0.5 * sin(ray.p.x * 5.0 + time * 2.0 + t1.r * 10.0));");
					writer.appendLine("	vec3 wave2 = t2 * (0.5 + 0.5 * cos(ray.p.y * 6.0 - time * 1.5 + t3.g * 8.0));");
					writer.appendLine("	return abs(wave1 + wave2 - t1*t3);"); // abs to keep it positive
				}

				// --- Using Texture Values as Modulators ---

				static void composition_0049_TextureAsMask(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	float mask = smoothstep(0.2, 0.8, t0.r + t0.g + t0.b / 3.0); // Luminance-like mask from t0");
					writer.appendLine("	vec3 masked = mix(t1, t2, mask);");
					writer.appendLine("	return mix(masked, t3, sin(time + ray.t * 0.1) * 0.5 + 0.5);");
				}

				static void composition_0050_TextureAsDisplacement(Writer& writer) {
					// This is conceptual for combining results; true displacement affects UVs
					// Here, we use one texture to "warp" the values of another
					prependTextureFetches(writer);
					writer.appendLine("	vec3 warpFactor = (t0 - 0.5) * 2.0; // Range -1 to 1");
					writer.appendLine("	vec3 warped_t1 = t1 + warpFactor * 0.2 * sin(time);");
					writer.appendLine("	vec3 warped_t2 = t2 - warpFactor * 0.1 * cos(time);");
					writer.appendLine("	return mix(warped_t1, warped_t2, t3.b);");
				}

				static void composition_0051_ThresholdingAndOverlay(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	vec3 thresholded_t0 = step(vec3(0.5 + 0.1*sin(time)), t0); // Binary based on t0");
					writer.appendLine("	vec3 overlay_t1_t2;"); // simple overlay-like
					writer.appendLine("	if (dot(t1, vec3(1.0/3.0)) < 0.5) {");
					writer.appendLine("	    overlay_t1_t2 = 2.0 * t1 * t2;");
					writer.appendLine("	} else {");
					writer.appendLine("	    overlay_t1_t2 = vec3(1.0) - 2.0 * (vec3(1.0) - t1) * (vec3(1.0) - t2);");
					writer.appendLine("	}");
					writer.appendLine("	return mix(thresholded_t0 * overlay_t1_t2, t3, clamp(ray.p.z * 0.1, 0.0, 1.0));");
				}

				// --- More Complex / Experimental ---

				static void composition_0052_SwizzleAndRecombine(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	vec3 r_comp = vec3(t0.r, t1.r, t2.r);");
					writer.appendLine("	vec3 g_comp = vec3(t1.g, t2.g, t3.g);");
					writer.appendLine("	vec3 b_comp = vec3(t2.b, t3.b, t0.b);");
					writer.appendLine("	float lerpFactor = (sin(time * 0.7 + ray.p.x) + 1.0) * 0.5;");
					writer.appendLine("	vec3 final_r = mix(r_comp, g_comp, lerpFactor);");
					writer.appendLine("	vec3 final_g = mix(g_comp, b_comp, fract(lerpFactor * 1.5));");
					writer.appendLine("	vec3 final_b = mix(b_comp, r_comp, fract(lerpFactor * 2.0));");
					writer.appendLine("	return vec3(final_r.x, final_g.y, final_b.z) * (abs(sin(t3.x + t2.y + t1.z + time)));");
				}

				static void composition_0053_FresnelLikeEdgeBlend(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	vec3 viewDir = normalize(-ray.p); // Assuming ray.p is world space position and camera is at origin");
					writer.appendLine("	float fresnel = pow(1.0 - max(0.0, dot(viewDir, ray.normal)), 3.0);");
					writer.appendLine("	vec3 edgeColor = t0 * (0.5 + 0.5 * sin(time * 5.0 + ray.t));");
					writer.appendLine("	vec3 centerColor = mix(t1, t2, t3.b);");
					writer.appendLine("	return mix(centerColor, edgeColor, fresnel);");
				}

				static void composition_0017_CellularPatternInfluence(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("	vec2 p_norm = ray.p.xy * (2.0 + sin(time*0.1)); // Scale position for pattern");
					writer.appendLine("	vec2 p_int = floor(p_norm);");
					writer.appendLine("	vec2 p_fract = fract(p_norm);");
					writer.appendLine("	float random_cell = fract(sin(dot(p_int, vec2(12.9898,78.233))) * 43758.5453);");
					writer.appendLine("	float dist_to_center = length(p_fract - 0.5);");
					writer.appendLine("	float cell_factor = smoothstep(0.5, 0.45, dist_to_center) * random_cell;");
					writer.appendLine("	vec3 c1 = mix(t0, t1, cell_factor);");
					writer.appendLine("	vec3 c2 = mix(t2, t3, 1.0 - cell_factor);");
					writer.appendLine("	return mix(c1, c2, smoothstep(0.0, 1.0, t0.r * random_cell));");
				}

				static void composition_0054_TimeScaledFeedbackLoop(Writer& writer) {
					// This is a conceptual feedback - true feedback needs render targets.
					// We simulate it by using one texture's value from a "previous frame" (modulated by time).
					prependTextureFetches(writer);
					writer.appendLine("	vec3 prev_t0_sim = t0 * (0.5 + 0.5 * sin(time * -0.5 + t0.r * 2.0)); // Simulate t0 from a bit ago");
					writer.appendLine("	vec3 current_mix = mix(t1, t2, t3.g);");
					writer.appendLine("	return mix(current_mix, prev_t0_sim, clamp(length(ray.p - vec3(0,0,1)) * 0.1 * (0.5 + 0.5 * cos(time)), 0.0, 1.0));");
				}

				static void composition_0055_NormalAlignedStripes(Writer& writer) {
					prependTextureFetches(writer);
					writer.appendLine("    vec3 up = vec3(0,1,0);");
					writer.appendLine("    vec3 right = cross(ray.normal, up);");
					writer.appendLine("    if (length(right) < 0.01) right = vec3(1,0,0); else right = normalize(right);");
					writer.appendLine("    float stripe_coord = dot(ray.p, right) * (5.0 + 3.0 * sin(time*0.2));");
					writer.appendLine("    float stripe_pattern = smoothstep(0.3, 0.7, fract(stripe_coord + t0.r));");
					writer.appendLine("    vec3 color1 = mix(t1, t2, 0.5 + 0.5 * sin(time));");
					writer.appendLine("    vec3 color2 = mix(t2, t3, 0.5 + 0.5 * cos(time));");
					writer.appendLine("    return mix(color1, color2, stripe_pattern);");
				}

				static void composition_0056_VolumetricDensitySim(Writer& writer)
				{
					prependTextureFetches(writer);
					writer.appendLine("    float density1 = t0.r * t1.g * (0.5 + 0.5 * sin(ray.p.z * 2.0 + time));");
					writer.appendLine("    float density2 = t2.b * t3.b * (0.5 + 0.5 * cos(ray.p.x * 2.0 - time));");
					writer.appendLine("    float total_density = clamp(density1 + density2 * (1.0 - density1), 0.0, 1.0);");
					writer.appendLine("    vec3 color_at_density = mix(t0, t1, density1) + mix(t2, t3,density2);");
					writer.appendLine("    return pow(color_at_density, vec3(1.0 / (1.0 + total_density * 2.0))) * total_density;");
				}








				// Combines sine and cosine modulation with global time and ray travel distance.
				static void composition_0057(Writer& writer)
				{
					writer.appendLine("    return abs(sin(texture_wave_0(ray) + time) * cos(texture_wave_1(ray) + ray.t) + mix(texture_wave_2(ray), texture_wave_3(ray), 0.5));");
				}

				// Uses ray position length as a factor in mixing, adding a spatially-varying blend.
				static void composition_0058(Writer& writer)
				{
					writer.appendLine("    return mix(texture_wave_0(ray), texture_wave_1(ray), clamp(sin(length(ray.p)), 0.0, 1.0)) + mix(texture_wave_2(ray), texture_wave_3(ray), clamp(ray.t * 0.1, 0.0, 1.0));");
				}

				// Applies power and square-root functions to give different weights to the texture channels.
				static void composition_0059(Writer& writer)
				{
					writer.appendLine("    return abs(pow(texture_wave_0(ray), vec3(2.0)) - sqrt(abs(texture_wave_1(ray))) + texture_wave_2(ray) * texture_wave_3(ray));");
				}

				// Blends textures based on the ray's normal and position components;
				// the dot product between the normal and an upward vector creates a lighting-like effect.
				static void composition_0060(Writer& writer)
				{
					writer.appendLine("    return mix(texture_wave_0(ray), texture_wave_1(ray), clamp(dot(normalize(ray.normal), vec3(0.0, 1.0, 0.0)), 0.0, 1.0)) + sin(texture_wave_2(ray) * dot(ray.p, vec3(1.0))) * cos(texture_wave_3(ray) * ray.t);");
				}

				// Uses time-dependent sine and cosine functions in additive combination.
				static void composition_0061(Writer& writer)
				{
					writer.appendLine("    return abs(sin(texture_wave_0(ray) + texture_wave_1(ray) * sin(time)) + cos(texture_wave_2(ray) - texture_wave_3(ray) * cos(time)));");
				}

				// Combines a frequency modulation using ray travel distance with a mix that is time-dependent.
				static void composition_0062(Writer& writer)
				{
					writer.appendLine("    return texture_wave_0(ray) * (sin(ray.t * 3.1415) + 0.5) + texture_wave_1(ray) * cos(ray.t * 3.1415) + mix(texture_wave_2(ray), texture_wave_3(ray), (sin(time) + 1.0) * 0.5);");
				}

				// Employs the ray's iteration count to drive a modulated mix of textures.
				static void composition_0063(Writer& writer)
				{
					writer.appendLine("    return mix(texture_wave_0(ray), texture_wave_1(ray), abs(sin(time + float(ray.i)))) * mix(texture_wave_2(ray), texture_wave_3(ray), abs(cos(time + float(ray.i))));");
				}

				// Uses power functions to create contrasting intensities between texture pairs.
				static void composition_0064(Writer& writer)
				{
					writer.appendLine("    return abs(pow(texture_wave_0(ray) + texture_wave_1(ray), vec3(1.5)) - pow(texture_wave_2(ray) + texture_wave_3(ray), vec3(0.5)));");
				}

				// Mixes sine and cosine of summed textures, creating a periodic fluctuation.
				static void composition_0065(Writer& writer)
				{
					writer.appendLine("    return mix(sin(texture_wave_0(ray) + texture_wave_1(ray)), cos(texture_wave_2(ray) + texture_wave_3(ray)), 0.5);");
				}


			};

			std::vector<std::function<void(Writer&)>> function_vector_texture_compositions;
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0000);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0001);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0002);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0003);

			function_vector_texture_compositions.push_back(TextureCompositions::composition_0004);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0005);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0006);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0007);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0008);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0009);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0010);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0011);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0012);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0013);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0014);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0015);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0016);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0017);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0018);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0019);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0020);

			function_vector_texture_compositions.push_back(TextureCompositions::composition_0021);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0022);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0023);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0024);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0025);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0026);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0027);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0028);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0029);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0030);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0031);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0032);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0033);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0034);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0035);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0036);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0037);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0038);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0039);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0040);

			function_vector_texture_compositions.push_back(TextureCompositions::composition_0041_WeightedSumTime);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0042_MultiplyAndLerp);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0043_RayDistanceBlend);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0044_RayNormalModulation);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0045_RayIterationPattern);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0046_RayPositionFractal);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0047_SinCosPowerMix);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0048_LayeredWaves);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0049_TextureAsMask);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0050_TextureAsDisplacement);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0051_ThresholdingAndOverlay);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0052_SwizzleAndRecombine);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0053_FresnelLikeEdgeBlend);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0054_TimeScaledFeedbackLoop);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0055_NormalAlignedStripes);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0056_VolumetricDensitySim);

			function_vector_texture_compositions.push_back(TextureCompositions::composition_0057);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0058);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0059);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0060);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0061);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0062);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0063);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0064);
			function_vector_texture_compositions.push_back(TextureCompositions::composition_0065);


			w_definitons.appendLine("vec3 texture_generated(Ray ray)");
			w_definitons.appendLine("{");

			Random::random_element(function_vector_texture_compositions)(w_definitons);

			w_definitons.appendLine("}");
		}


		{

			struct Sdf_compose
			{
				static void compose_0000(Line& line)
				{
					line.add("float d_out_0 = mix(sd_0(cube_space), sd_1(cube_space), abs(sin(time * 0.27 * " + std::to_string(Random::generate_random_float_minus_one_to_plus_one()) + ")));");
					line.add("float d_out_1 = mix(sd_2(cube_space), sd_3(cube_space), abs(sin(time * 0.27 * " + std::to_string(Random::generate_random_float_minus_one_to_plus_one()) + ")));");

					line.add("float d_out_2 = mix(sd_4(cube_space), sd_5(cube_space), abs(sin(time * 0.27 * " + std::to_string(Random::generate_random_float_minus_one_to_plus_one()) + ")));");
					line.add("float d_out_3 = mix(sd_6(cube_space), sd_7(cube_space), abs(sin(time * 0.27 * " + std::to_string(Random::generate_random_float_minus_one_to_plus_one()) + ")));");

					line.add("float d_out_0123 = mix(mix(d_out_0, d_out_1, 0.47 + 0.2 * sin(time + cube_space.x * 10.0)), mix(d_out_2, d_out_3, 0.47 + 0.2 * sin(-time * 0.97 + cube_space.y * 10.0)), 0.47 + 0.2 * sin(time));");
					line.add("float d_out_x = mix( sd_8(cube_space), sd_9(cube_space), 0.47);");

					line.add("float d_out = mix(d_out_0123, d_out_x, 0.5 + sin(cube_space.x * cube_space.y * cube_space.z * 100.0 + time * 2.7));");
				}

				static void compose_0001(Line& line)
				{

					line.add("float d_a = mix(sd_0(cube_space), sd_3(cube_space), smoothstep(-1.0, 1.0, sin(time * 0.5 + cube_space.z * 5.0)));");


					line.add("float d_b = mix(sd_1(cube_space), sd_4(cube_space), 0.5 + 0.5 * sin(time * 0.33 + atan(cube_space.y, cube_space.x)));");


					line.add("float d_temp = mix(sd_2(cube_space), sd_5(cube_space), abs(sin(time * 0.42 + cube_space.y * 8.0)));");
					line.add("float d_c = mix(d_temp, sd_7(cube_space), 0.5 + 0.5 * sin(time * 1.17 + cube_space.x * cube_space.z * 4.0));");


					line.add("float threshold = step(0.0, sin(time * 0.9 + cube_space.y * 3.0));");
					line.add("float d_d = mix(sd_6(cube_space), sd_8(cube_space), threshold);");


					line.add("float sphere_wave = 0.5 + 0.5 * sin(length(cube_space) * 10.0 - time * 2.0);");
					line.add("float d_e = mix(d_c, sd_9(cube_space), sphere_wave);");


					line.add(
						"float d_ab = mix(d_a, d_b, 0.5 + 0.5 * sin(time * 0.77 + cube_space.x * 6.0));\n"
						"float d_de = mix(d_d, d_e, 0.5 + 0.5 * sin(time * 1.23 + cube_space.y * 6.0));\n"
						"float d_out = mix(d_ab, d_de, 0.5 + 0.5 * sin(time * 0.94 + cube_space.z * 6.0));"
					);
				}

				static void compose_0002(Line& line)
				{
					// Smoothly blend sd_0 and sd_1 using spatially varying smooth min
					line.add("float k0 = 0.3 + 0.2 * sin(time * 0.8 + cube_space.x * 5.0);");
					line.add("float d0 = smin(sd_0(cube_space), sd_1(cube_space), k0);");

					// Use smin to merge sd_2 and sd_3 with a pulsating factor based on z-coordinate
					line.add("float k1 = 0.2 + 0.2 * abs(sin(time * 1.1 + cube_space.z * 7.0));");
					line.add("float d1 = smin(sd_2(cube_space), sd_3(cube_space), k1);");

					// Interweave sd_4 and sd_5 by first blending them, then smoothing with sd_6
					line.add("float mix01 = smin(d0, d1, 0.25);");
					line.add("float k2 = 0.4 + 0.1 * sin(time * 0.65 + cube_space.y * 6.0);");
					line.add("float d2 = smin(mix01, sd_6(cube_space), k2);");

					// Joyful spiral blend between sd_7 and sd_8
					line.add("float angle = atan(cube_space.y, cube_space.x) + time * 0.5;");
					line.add("float radius = length(cube_space.xy) * 2.0;");
					line.add("float weight = 0.5 + 0.5 * sin(angle * 3.0 + radius * 4.0);");
					line.add("float d3 = smin(sd_7(cube_space), sd_8(cube_space), 0.3 + 0.2 * weight);");

					// Merge sd_9 into the composition with a bouncing sphere wave
					line.add("float sphere_bounce = 0.5 + 0.5 * sin(length(cube_space) * 8.0 - time * 2.5);");
					line.add("float d4 = smin(d2, sd_9(cube_space), 0.2 + 0.2 * sphere_bounce);");

					// Final joyful combination: chain smin of d3 and d4, modulated by time
					line.add("float k_final = 0.3 + 0.15 * sin(time * 1.3 + cube_space.x * cube_space.y * 5.0);");
					line.add("float d_out = smin(d3, d4, k_final);");
				}

				static void compose_0003(Line& line)
				{
					// Create a dance between sd_0 and sd_2 with a wavy threshold modulated by x and y
					line.add("float k0 = 0.2 + 0.2 * abs(sin(time * 0.7 + cube_space.x * cube_space.y * 4.0));");
					line.add("float d0 = smin(sd_0(cube_space), sd_2(cube_space), k0);");

					// Blend sd_1 and sd_3 through a spinning swirl around the z axis
					line.add("float ang1 = atan(cube_space.y, cube_space.x) * 2.0 + time * 0.6;");
					line.add("float swirl = 0.5 + 0.5 * sin(ang1 + length(cube_space.xy) * 6.0);");
					line.add("float d1 = mix(sd_1(cube_space), sd_3(cube_space), swirl);");

					// Merge the previous result with sd_4 using a pulsating spherical shell
					line.add("float shell = abs(sin(length(cube_space) * 5.0 - time * 1.8));");
					line.add("float d2 = smin(d1, sd_4(cube_space), 0.3 + 0.2 * shell);");

					// Sync sd_5 and sd_6 via a checkerboard pattern in space that flips over time
					line.add("float checker = step(0.5, fract((cube_space.x + cube_space.y + time) * 3.0));");
					line.add("float d3 = mix(sd_5(cube_space), sd_6(cube_space), checker);");

					// Smoothly join sd_7 and sd_8 with a sliding plane that moves diagonally
					line.add("float slide = smoothstep(-1.0, 1.0, cube_space.x + cube_space.y - sin(time * 0.9));");
					line.add("float d4 = mix(sd_7(cube_space), sd_8(cube_space), slide);");

					// Introduce sd_9 by softly infusing it into d2 and d3 in a time woven fashion
					line.add("float weave = 0.5 + 0.5 * sin(time * 1.2 + cube_space.z * 7.0);");
					line.add("float d5 = smin(d2, sd_9(cube_space), 0.25 + 0.2 * weave);");
					line.add("float d6 = mix(d3, d4, 0.5 + 0.5 * sin(time * 0.85 + cube_space.x * 4.0));");

					// Final vibrant composition: softly smooth min d5 and d6, modulated by a 3D wave
					line.add("float wave3d = 0.5 + 0.5 * sin(cube_space.x * cube_space.y * cube_space.z * 12.0 - time * 2.2);");
					line.add("float k_final = 0.3 + 0.2 * wave3d;");
					line.add("float d_out = smin(d5, d6, k_final);");
				}
			};


			std::vector<std::function<void(Line&)>> function_vector_sdf_compose;
			function_vector_sdf_compose.push_back(Sdf_compose::compose_0000);
			function_vector_sdf_compose.push_back(Sdf_compose::compose_0001);
			function_vector_sdf_compose.push_back(Sdf_compose::compose_0002);
			function_vector_sdf_compose.push_back(Sdf_compose::compose_0003);

			Line line;
			Random::random_element(function_vector_sdf_compose)(line);

			w_expression.appendLine(line.join());
		}


		// w_expression.appendLine("float dmix = mix(d_sphere, d_cube, factor);");
		// w.appendLine("v = smin(v, mix(d_sphere, d_cube, abs(sin(time))), 0.1);");

		std::string factor = std::to_string(0.01f + Random::generate_random_float_0_to_1() * 0.2f);

		w_expression.appendLine("v = smin(v, d_out, " + factor + "); ");

	}

	void run_write_to_file_shaders()
	{
		const std::string folder = "generated_shaders";
		const std::string file_path = folder + "/" + "example.glsl";

		const int number_of_shader_per_room = 100;

		Folder::create_folder_if_does_not_exist_already(folder);
		// File::writeFile_OverrideIfExistAlready(file_path, "this is content of glsl shader");

		// Create the rooms shaders
		std::string room_0_folder = folder + "/" + "room_0";
		std::string room_1_folder = folder + "/" + "room_1";
		std::string room_2_folder = folder + "/" + "room_2";
		std::string room_3_folder = folder + "/" + "room_3";
		{

			Folder::create_folder_if_does_not_exist_already(room_0_folder);
			Folder::create_folder_if_does_not_exist_already(room_1_folder);
			Folder::create_folder_if_does_not_exist_already(room_2_folder);
			Folder::create_folder_if_does_not_exist_already(room_3_folder);
		}

		// generate shaders room 0
		for (int i = 0; i < number_of_shader_per_room; i++)
		{
			std::string shader_file_path = room_0_folder + "/" + "shader_" + std::to_string(i) + ".glsl";


			Writer w_expression;
			Writer w_funciton_definition;

			w_expression.appendLine("// generated code goes here");

			generate_shader_0(w_funciton_definition, w_expression);


			w_expression.appendLine("// end generated code goes");

			{
				Writer writer;

				writer.appendLinesFromFile("generated_shaders/base.glsl");

				writer.replaceAll("//#REPLACE_INSIDE_MAP_FUNCTION", w_expression.join());
				writer.replaceAll("//#REPLACE_FUNCTION_DEFINITIONS", w_funciton_definition.join());


				writer.writeToFileOverride(shader_file_path);
			}


		}

		// generate shaders room 1
		for (int i = 0; i < number_of_shader_per_room; i++)
		{
			std::string shader_file_path = room_1_folder + "/" + "shader_" + std::to_string(i) + ".glsl";

			Writer w_expression;
			Writer w_funciton_definition;

			w_expression.appendLine("// generated code goes here");

			generate_shader_0(w_funciton_definition, w_expression);


			w_expression.appendLine("// end generated code goes");

			{
				Writer writer;

				writer.appendLinesFromFile("generated_shaders/base.glsl");

				writer.replaceAll("//#REPLACE_INSIDE_MAP_FUNCTION", w_expression.join());
				writer.replaceAll("//#REPLACE_FUNCTION_DEFINITIONS", w_funciton_definition.join());


				writer.writeToFileOverride(shader_file_path);
			}

		}

		// generate shaders room 2
		for (int i = 0; i < number_of_shader_per_room; i++)
		{
			std::string shader_file_path = room_2_folder + "/" + "shader_" + std::to_string(i) + ".glsl";

			Writer w;

			Writer w_expression;
			Writer w_funciton_definition;

			w_expression.appendLine("// generated code goes here");

			generate_shader_0(w_funciton_definition, w_expression);


			w_expression.appendLine("// end generated code goes");

			{
				Writer writer;

				writer.appendLinesFromFile("generated_shaders/base.glsl");

				writer.replaceAll("//#REPLACE_INSIDE_MAP_FUNCTION", w_expression.join());
				writer.replaceAll("//#REPLACE_FUNCTION_DEFINITIONS", w_funciton_definition.join());


				writer.writeToFileOverride(shader_file_path);
			}

		}

		// generate shaders room 3
		for (int i = 0; i < number_of_shader_per_room; i++)
		{
			std::string shader_file_path = room_3_folder + "/" + "shader_" + std::to_string(i) + ".glsl";

			Writer w_expression;
			Writer w_funciton_definition;

			w_expression.appendLine("// generated code goes here");

			generate_shader_0(w_funciton_definition, w_expression);


			w_expression.appendLine("// end generated code goes");

			{
				Writer writer;

				writer.appendLinesFromFile("generated_shaders/base.glsl");

				writer.replaceAll("//#REPLACE_INSIDE_MAP_FUNCTION", w_expression.join());
				writer.replaceAll("//#REPLACE_FUNCTION_DEFINITIONS", w_funciton_definition.join());


				writer.writeToFileOverride(shader_file_path);
			}

		}


		Writer w;

		if (false)
		{
			w.appendLine("// generated code goes here");
			w.appendLine("float d_cube = sdRoundBox");
			w.appendLine("(");
			w.appendLine("cube_space,");
			w.appendLine("vec3(0.47 * 0.1, 0.47 * 0.1, 0.47 * 0.1),");
			w.appendLine("0.02");
			w.appendLine(");");

			// w.appendLine("float factor = 0.2;");

			w.appendLine("float factor = " + std::to_string(Random::random_float(0.0, 1.0)) + "; ");
			// w.appendLine("float d_sphere = sdSphere(cube_space, 0.2);");

			w.appendLine("float d_sphere = sdSphere(cube_space, " + std::to_string(Random::random_float(0.1, 0.7)) + "); ");

			w.appendLine("float dmix = mix(d_sphere, d_cube, factor);");
			w.appendLine("v = smin(v, mix(d_sphere, d_cube, abs(sin(time))), 0.1);");

			w.appendLine("// end generated code goes");
		}

		if (false)
		{
			// w.appendLine("// generated code goes here");

			/*
			w.appendLine("float d_cube = sdRoundBox");
			w.appendLine("(");
			w.appendLine("cube_space,");
			w.appendLine("vec3(0.47 * 0.1, 0.47 * 0.1, 0.47 * 0.1),");
			w.appendLine("0.02");
			w.appendLine(");");

			w.appendLine("float factor = 0.2;");
			w.appendLine("float d_sphere = sdSphere(cube_space, 0.2);");
			w.appendLine("float dmix = mix(d_sphere, d_cube, factor);");
			w.appendLine("v = smin(v, mix(d_sphere, d_cube, abs(sin(time))), 0.1);");
			*/

			/*
			std::vector<std::string> txt =
			{
				"v = smin",
				"(",
				"v,"
				"sdSphere",
					"(",
						"cube_space,",
						std::to_string(Random::random_float(0.1f, 0.47f)),
					"),",
				std::to_string(0.02f),
				");"
			};
			*/

			// sdSphere(#RND_FLOAT_0_1 * 0.2)


			/*
			Line line;
			line.add("v = ");
			line.add("smin");
			line.add("(");
			line.add("v,");
			line.add("sdSphere");
			line.add("(");
				line.add("cube_space, ");
				line.add(std::to_string(Random::random_float(0.1f, 0.47f)));
			line.add("),");

			line.add(std::to_string(0.02f));
			line.add(");");

			w.appendLine(line.join());

			w.appendLine("// end generated code goes");
			*/

			// sdSphere(p + position, radius)
			// sdSphere(p + position, radius)

			// sphere 
			// position
			// radius

			// sphere_ulika
			// positon
			// radius_0
			// radius_1
			// radius_frequency_0
			// power_function
			// noise_0
			//  parameter_a
			//  parameter_b
			//  parameter_c

			// torus
			// position
			// scale
			// size_ring_small
			// size_ring_big
			// frequency_0_ring_small
			// frequency_0_ring_big

			// mix
			// value_base
			// value_amplitude
			// value_frequency
			// (0.5 + * 0.5 * sin(p.x)) * wave_factor_x
			// (0.5 + * 0.5 * sin(p.y)) * wave_factor_y
			// (0.5 + * 0.5 * sin(p.z)) * wave_factor_z







		}


		if (true)
		{
			Writer writer;


			writer.appendLine(f_embeded_GLSL_source_base_glsl());

			writer.replaceAll("//#REPLACE_INSIDE_MAP_FUNCTION", w.join());

			writer.writeToFileOverride(file_path);
		}

	}

	ShaderRuntime* generate_shader()
	{
		std::string source_code_fragment_shader = "";

		// generating fragment shader source
		{
			Writer w_expression;
			Writer w_funciton_definition;

			{
				w_expression.appendLine("// generated code goes here");
				generate_shader_0(w_funciton_definition, w_expression);
				w_expression.appendLine("// end generated code goes");
			}

			Writer writer;

			writer.appendLine(f_embeded_GLSL_source_base_glsl());

			writer.replaceAll("//#REPLACE_INSIDE_MAP_FUNCTION", w_expression.join());
			writer.replaceAll("//#REPLACE_FUNCTION_DEFINITIONS", w_funciton_definition.join());

			source_code_fragment_shader = writer.join();
		}

		// vertex shader source
		std::string vertex_shader = f_embeded_GLSL_source_vertex_shader_exploring_0000();


		ShaderRuntime* shader = ShaderRuntime_::create(vertex_shader.c_str(), source_code_fragment_shader.c_str());
		assert(shader != nullptr);

		return shader;
	}

}