import argparse
import json
import re
import subprocess
from collections import defaultdict
import datetime


def fetch_aws_images_by_tag(tag_key, tag_value, region):
    try:
        command = [
            "aws", "ec2", "describe-images",
            "--filters", f"Name=tag:{tag_key},Values={tag_value}",
            "--region", region,
            "--output", "json"
        ]
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error fetching images: {e}")
        return None


def group_aws_images_by_tag(images, tag_key):
    groups = defaultdict(list)
    for image in images:
        env_tag = next((tag['Value'] for tag in image['Tags'] if tag['Key'] == tag_key), None)
        if env_tag:
            groups[env_tag].append(image)
    return groups


def sort_aws_images_by_creation_date(images):
    for key in images:
        images[key].sort(key=lambda x: datetime.datetime.strptime(x['CreationDate'], '%Y-%m-%dT%H:%M:%S.%fZ'),
                         reverse=True)


def fetch_aws_images(args):
    json_output = {}
    for region in args.aws_regions:
        for images_info in [fetch_aws_images_by_tag("Project", args.project_name, region)]:
            if images_info and images_info.get('Images'):
                images = images_info['Images']
                grouped_images = group_aws_images_by_tag(images, "Environment")
                sort_aws_images_by_creation_date(grouped_images)
                for environment, imgs in grouped_images.items():
                    if len(imgs) >= args.image_count_upper_limit:
                        json_output[environment] = [{'name': img['Name'], 'id': img['ImageId'], 'provider': 'aws', 'region': region} for img in
                                                    imgs[args.image_count_lower_limit:]]
    return json_output


def fetch_gcp_images_by_project(project, label):
    try:
        command = [
            "gcloud", "compute", "images", "list",
            "--project", project,
            "--filter", f"labels.project={label}",
            "--format", "json"
        ]
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        if result.returncode != 0:
            print(f"Error fetching GCP images: {result.stderr}")
            return {}
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error fetching GCP images: {e}")
        return {}


def fetch_gcp_images_by_projects(project_to_environments, label):
    images = defaultdict(list)
    for project, environment in project_to_environments.items():
        for image in fetch_gcp_images_by_project(project, label):
            images[environment].append(image)
    return images


def sort_gcp_images_by_creation_date(images):
    for key in images:
        images[key].sort(key=lambda x: datetime.datetime.strptime(x['creationTimestamp'], '%Y-%m-%dT%H:%M:%S.%f%z'),
                         reverse=True)


def fetch_gcp_images(args):
    projects = {
        'concordium-mgmt-0':        'BaseImage',
        'concordium-stagenet-0':    'Stagenet',
        'concordium-testnet-0':     'Testnet',
        'concordium-mainnet-0':     'Mainnet'
    }
    json_output = {}
    gcp_images = fetch_gcp_images_by_projects(projects, re.sub(r'([A-Z])', r'_\1', args.project_name).lower().strip('_'))
    if gcp_images:
        sort_gcp_images_by_creation_date(gcp_images)
        for environment, imgs in gcp_images.items():
            if len(imgs) >= args.image_count_upper_limit:
                json_output[environment] = [{'name': img['name'], 'id': img['id'], 'provider': 'gcp'} for img in
                                            imgs[args.image_count_lower_limit:]]
    return json_output


def main(args):
    aws_images = fetch_aws_images(args)
    gcp_images = fetch_gcp_images(args)
    json_output = {key: aws_images.get(key, []) + gcp_images.get(key, []) for key in aws_images.keys() | gcp_images.keys()}
    print(json.dumps(json_output))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Report the oldest images to a file ignoring the newest images provided by the limit.")
    parser.add_argument('--image_count_lower_limit', type=int, default=10,
                        help='The limit indicating where to report images down to. Those images are meant for de-registering')
    parser.add_argument('--image_count_upper_limit', type=int, default=20,
                        help='The limit indicating when to start reporting that images has to be de-registered')
    parser.add_argument('--aws_regions', type=str, nargs='+', help='AWS region to fetch images from.')
    parser.add_argument('--project_name', type=str, default='ConcordiumNode', help='Project name to query tags by')
    args = parser.parse_args()
    main(args)
