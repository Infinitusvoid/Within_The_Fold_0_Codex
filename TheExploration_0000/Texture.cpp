#include "Texture.h"

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <assert.h>

#include <iostream>

#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <unordered_map>
#include <vector>



namespace Texture_
{
	static std::queue<std::function<void()>> g_uploadQueue;
	static std::mutex                          g_uploadQueueMutex;


	void set_texture_unit(Texture& texture, int texture_unit)
	{
		// 1) Non-negative:
		assert(texture_unit >= 0);

		// 2) Below the hardware limit:
		GLint maxUnits = 0;
		glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &maxUnits);
		assert(texture_unit < maxUnits && "Texture unit out of range");

		texture.gl.texture_unit = texture_unit;
	}

	void unbind()
	{
		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void create(Texture& texture, int texture_unit)
	{
		set_texture_unit(texture, texture_unit);

		glGenTextures(1, &texture.gl.id);
		glBindTexture(GL_TEXTURE_2D, texture.gl.id);
		// set the texture wrapping parameters
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		// set texture filtering parameters
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		unbind();
	}

	void bind(Texture& texture)
	{
		GLenum slot = GL_TEXTURE0 + texture.gl.texture_unit;
		glActiveTexture(slot);
		glBindTexture(GL_TEXTURE_2D, texture.gl.id);
	}


	/*
	* Load image from file and upload it to the GPU than cleans the image
	*/
	bool load_from_file(Texture& texture, const char* image_file_path)
	{
		bind(texture);

		{
			ImageRGBA* image = ImageRGBA_::load(image_file_path);

			if (!image) {
				std::cerr << "Failed to load image: " << image_file_path << std::endl;
				return false;
			}

			ImageRGBA_::readonly_raw_direct_access(*image, [&](int width, int height, const unsigned char* data) {

				texture.width = width;
				texture.height = height;

				// note that the awesomeface.png has transparency and thus an alpha channel, so make sure to tell OpenGL the data type is of GL_RGBA
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
				glGenerateMipmap(GL_TEXTURE_2D);
				});

			ImageRGBA_::free_image(image);


		}

		unbind();

		return true;
	}

	bool replace_texture(Texture& texture, const char* image_file_path)
	{
		bind(texture);

		ImageRGBA* image = ImageRGBA_::load(image_file_path);
		if (!image) {
			std::cerr << "Failed to load image: " << image_file_path << std::endl;
			return false;
		}

		bool same_size = true;
		int new_width = 0, new_height = 0;

		ImageRGBA_::readonly_raw_direct_access(*image, [&](int width, int height, const unsigned char* data) {
			new_width = width;
			new_height = height;
			same_size = (texture.width == width && texture.height == height);

			if (same_size) {

				glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
			}
			else
			{
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
				texture.width = width;
				texture.height = height;
			}

			glGenerateMipmap(GL_TEXTURE_2D);
			});

		ImageRGBA_::free_image(image);
		unbind();
		return true;
	}

	// 1) Create a new blank image, fill it procedurally, and upload it.
	bool create_procedural
	(
		Texture& texture,
		int width,
		int height,
		std::function<RGBA(float u, float v)> f_generator
	)
	{

		// If we already have a texture, delete it and reset:
		if (texture.gl.id != 0)
		{
			free(texture);
		}

		std::vector<unsigned char> pixels;;
		pixels.resize(static_cast<size_t>(width) * height * 4);

		// 2. Fill with generator(u,v)
		float invW = 1.0f / width;
		float invH = 1.0f / height;
		for (int y = 0; y < height; ++y) {
			for (int x = 0; x < width; ++x) {
				float u = x * invW;
				float v = y * invH;

				RGBA c = f_generator(u, v);

				int idx = (y * width + x) * 4;
				pixels[idx + 0] = c.r;
				pixels[idx + 1] = c.g;
				pixels[idx + 2] = c.b;
				pixels[idx + 3] = c.a;
			}
		}

		// 3. Create GPU texture and upload
		create(texture, texture.gl.texture_unit);   // assumes unit already set
		bind(texture);
		glTexImage2D
		(
			GL_TEXTURE_2D,
			0,
			GL_RGBA,
			width, height,
			0,
			GL_RGBA,
			GL_UNSIGNED_BYTE,
			pixels.data()
		);
		glGenerateMipmap(GL_TEXTURE_2D);
		unbind();

		// 4. Store dimensions if you’ll need them later
		texture.width = width;
		texture.height = height;

		return true;
	}


	bool create_from_ImageRGBA
	(
		Texture& texture,
		ImageRGBA& image
	)
	{

		// If we already have a texture, delete it and reset:
		if (texture.gl.id != 0)
		{
			free(texture);
		}

		// 3. Create GPU texture and upload
		create(texture, texture.gl.texture_unit);   // assumes unit already set
		bind(texture);
		ImageRGBA_::readonly_raw_direct_access
		(
			image, [&](int width, int height, const unsigned char* data)
			{
				texture.width = width;
				texture.height = height;
				glTexImage2D
				(
					GL_TEXTURE_2D,
					0,
					GL_RGBA,
					width, height,
					0,
					GL_RGBA,
					GL_UNSIGNED_BYTE,
					data
				);

				glGenerateMipmap(GL_TEXTURE_2D);
			}
		);
		unbind();
		return true;
	}

	// 2) Read back, apply per-pixel UV function, then re-upload.
	bool update_procedural
	(
		Texture& texture,
		std::function<RGBA(RGBA old, float u, float v)> f_modifier
	)
	{
		// 1. Allocate a CPU buffer to read the current texture
		int w = texture.width, h = texture.height;

		assert(texture.width > 0 && texture.height > 0);

		std::vector<unsigned char> cpuBuf(w * h * 4);

		bind(texture);
		glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, cpuBuf.data());

		// 2. Walk each pixel
		float invW = 1.0f / w, invH = 1.0f / h;
		for (int y = 0; y < h; ++y) {
			for (int x = 0; x < w; ++x) {
				int idx = (y * w + x) * 4;
				RGBA old{
					cpuBuf[idx + 0], cpuBuf[idx + 1],
					cpuBuf[idx + 2], cpuBuf[idx + 3]
				};
				float u = x * invW, v = y * invH;
				RGBA nw = f_modifier(old, u, v);
				cpuBuf[idx + 0] = nw.r;
				cpuBuf[idx + 1] = nw.g;
				cpuBuf[idx + 2] = nw.b;
				cpuBuf[idx + 3] = nw.a;
			}
		}

		// 3. Re-upload via TexSubImage (no realloc)
		glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, cpuBuf.data());
		glGenerateMipmap(GL_TEXTURE_2D);

		unbind();

		return true;
	}

	void free(Texture& texture)
	{
		glDeleteTextures(1, &texture.gl.id);
		texture.gl.id = 0;
	}





















	bool async_generate_and_upload
	(
		Texture& tex,
		int width, int height,
		std::function<RGBA(float u, float v)> generator
	)
	{
		// 1) Ensure the GPU texture exists
		if (tex.gl.id == 0) {
			create(tex, tex.gl.texture_unit);
		}

		// 2) Grab a fresh CPU buffer
		auto buf = std::make_shared<std::vector<unsigned char>>();
		buf->resize(size_t(width) * height * 4);

		// 3) Launch the worker thread (detached!)
		std::thread([&, buf, width, height, generator]() {
			// CPU: fill the buffer
			float invW = 1.f / width, invH = 1.f / height;
			for (int y = 0; y < height; ++y) {
				for (int x = 0; x < width; ++x) {
					RGBA c = generator(x * invW, y * invH);
					size_t i = (y * width + x) * 4;
					(*buf)[i + 0] = c.r;
					(*buf)[i + 1] = c.g;
					(*buf)[i + 2] = c.b;
					(*buf)[i + 3] = c.a;
				}
			}

			// 4) Enqueue the GL upload closure
			{
				std::lock_guard lk(g_uploadQueueMutex);
				g_uploadQueue.push([&, buf, width, height]() {
					bind(tex);
					if (tex.width != width || tex.height != height) {
						glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
							width, height, 0,
							GL_RGBA, GL_UNSIGNED_BYTE,
							buf->data());
						tex.width = width;
						tex.height = height;
					}
					else {
						glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0,
							width, height,
							GL_RGBA, GL_UNSIGNED_BYTE,
							buf->data());
					}
					glGenerateMipmap(GL_TEXTURE_2D);
					unbind();
					});
			}
			}).detach();

		// you get immediate return—no “busy” flag
		return true;
	}

	void process_all_async_uploads()
	{
		std::queue<std::function<void()>> local;

		{ // steal the queue under lock
			std::lock_guard lk(g_uploadQueueMutex);
			std::swap(local, g_uploadQueue);
		}

		// run each upload on this (main/GL) thread
		while (!local.empty()) {
			local.front()();
			local.pop();
		}
	}

}
















