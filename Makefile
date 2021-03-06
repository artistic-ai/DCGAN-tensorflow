.PHONY: all


SSH_KEY ?= ~/.ssh/MykhailoZiatin.pem
REMOTE_HOST ?= ec2-54-227-57-118.compute-1.amazonaws.com


train-flowers17-simplified:
	python main.py --dataset 17flowers_simplified --input_height=128 --is_crop True --input_fname_pattern "*.png" --is_train --samples_rate=100 --checkpoint_rate=100 --epoch 1000

test-flowers17-simplified:
	python main.py --dataset 17flowers_simplified --input_height=128 --is_crop True --input_fname_pattern "*.png"

train-anatoliy_belov-clips:
	python main.py --dataset anatoliy_belov-clips --input_height=300 --output_height=128 --is_crop True --input_fname_pattern "*.jpg" --is_train --samples_rate=50 --c_dim=1 --checkpoint_rate=100 --epoch 2500

test-anatoliy_belov-clips:
	python main.py --dataset anatoliy_belov-clips --input_height=300 --output_height=128 --is_crop True --c_dim=1 --input_fname_pattern "*.jpg"

gif: gif-train gif-arange

gif-train: clean-train fix-samples
	@echo "Create training gif animation" && \
	if [ -n "$(shell find samples -maxdepth 1 -type f \( -name "train_*.png" \))" ]; then \
	convert -delay 10 samples/train_*.png samples/animated_training.gif; \
	fi

gif-arange: clean-arange
	@echo "Create arange gif animation" && \
	if [ -n "$(shell find samples -maxdepth 1 -type f \( -name "test_arange_*.png" \))" ]; then \
	convert -delay 10 samples/test_arange_*.png samples/animated_arange.gif; \
	fi

mp4: mp4-train mp4-arange

mp4-train: gif-train
	@echo "Create training mp4 movie" && \
	if [ -f samples/animated_training.gif ]; then \
	ffmpeg -f gif -i samples/animated_training.gif -c:v libx264 -vf fps=30 -pix_fmt yuv420p samples/animated_training.mp4; \
	ffmpeg -i samples/animated_training.mp4 -filter:v "crop=1024:600:0:212" samples/animated_training-1024x600.mp4;  \
	fi

mp4-arange: gif-arange
	@echo "Create arange mp4 movie" && \
	if [ -f samples/animated_arange.gif ]; then \
	ffmpeg -f gif -i samples/animated_arange.gif -c:v libx264 -vf fps=30 -pix_fmt yuv420p samples/animated_arange.mp4; \
	ffmpeg -i samples/animated_arange.mp4 -filter:v "crop=1024:600:0:212" samples/animated_arange-1024x600.mp4;  \
	fi

clean: clean-train clean-arange

clean-train:
	@echo "Clean training animation" && \
	rm -f samples/animated_training.*

clean-arange:
	@echo "Clean arange animation" && \
	rm -f animated_arange.*

pack-models:
	@echo "Compress models" && \
	zip DCGAN-models.zip -r checkpoint

pack-samples: mp4
	@echo "Compress samples" && \
	zip DCGAN-samples.zip samples/*.gif samples/*.mp4 samples/*.png

publish: publish-models publish-samples

publish-models: pack-models
	@echo "Publish models" && \
	rm -f /home/ubuntu/DCGAN-models.zip && \
	mv DCGAN-models.zip /home/ubuntu

publish-samples: pack-samples
	@echo "Publish samples" && \
	rm -f /home/ubuntu/DCGAN-samples.zip && \
	mv DCGAN-samples.zip /home/ubuntu

scp: scp-models scp-samples

scp-samples:
	@echo "Copy remote samples" && \
	scp -i $(SSH_KEY) ubuntu@$(REMOTE_HOST):DCGAN-samples.zip .

scp-models:
	@echo "Copy remote models" && \
	scp -i $(SSH_KEY) ubuntu@$(REMOTE_HOST):DCGAN-models.zip .

unpack: unpack-models unpack-samples

unpack-models:
	@echo "Unpack models" && \
	unzip DCGAN-models.zip

unpack-samples:
	@echo "Unpack samples" && \
	unzip DCGAN-samples.zip

fix-samples:
	@echo "Fix samples names" && \
	./tools.py --fix_samples_filenames
